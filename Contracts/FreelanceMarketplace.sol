// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FreelanceMarketplace {
    uint256 public listingCount = 0;

    enum Status { Open, InProgress, Completed, Disputed }

    struct Listing {
        uint256 id;
        address client;
        address freelancer;
        string title;
        string description;
        uint256 price;
        Status status;
        bool paid;
    }

    mapping(uint256 => Listing) public listings;
    mapping(address => uint256[]) public userListings;

    event NewListing(uint256 indexed id, address indexed client);
    event ListingUpdated(uint256 indexed id);
    event TaskCompleted(uint256 indexed id, address indexed freelancer);
    event PaymentReleased(uint256 indexed id, address indexed freelancer);
    event DisputeRaised(uint256 indexed id);

    modifier onlyClient(uint256 _id) {
        require(msg.sender == listings[_id].client, "Only client can perform this action");
        _;
    }

    modifier onlyInvolved(uint256 _id) {
        require(msg.sender == listings[_id].client || msg.sender == listings[_id].freelancer, "Not authorized");
        _;
    }

    function setNewListing(string memory _title, string memory _description, uint256 _price) external payable {
        require(msg.value == _price, "Must send exact payment upfront");

        listings[listingCount] = Listing({
            id: listingCount,
            client: msg.sender,
            freelancer: address(0),
            title: _title,
            description: _description,
            price: _price,
            status: Status.Open,
            paid: false
        });

        userListings[msg.sender].push(listingCount);
        emit NewListing(listingCount, msg.sender);
        listingCount++;
    }

    function updateListing(uint256 _id, string memory _title, string memory _description, uint256 _price) external onlyClient(_id) {
        Listing storage l = listings[_id];
        require(l.status == Status.Open, "Cannot update non-open listing");

        l.title = _title;
        l.description = _description;
        l.price = _price;

        emit ListingUpdated(_id);
    }

    function fetchAllListings() external view returns (Listing[] memory) {
        Listing[] memory all = new Listing[](listingCount);
        for (uint256 i = 0; i < listingCount; i++) {
            all[i] = listings[i];
        }
        return all;
    }

    function fetchUserListings(address _user) external view returns (Listing[] memory) {
        uint256[] storage ids = userListings[_user];
        Listing[] memory userList = new Listing[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            userList[i] = listings[ids[i]];
        }
        return userList;
    }

    function fetchListingDetail(uint256 _id) external view returns (Listing memory) {
        return listings[_id];
    }

    function acceptListing(uint256 _id) external {
        Listing storage l = listings[_id];
        require(l.status == Status.Open, "Listing not available");
        l.freelancer = msg.sender;
        l.status = Status.InProgress;
    }

    function markTaskComplete(uint256 _id) external {
        Listing storage l = listings[_id];
        require(msg.sender == l.freelancer, "Only freelancer can mark as complete");
        require(l.status == Status.InProgress, "Task not in progress");

        l.status = Status.Completed;
        emit TaskCompleted(_id, msg.sender);
    }

    function releasePayment(uint256 _id) external onlyClient(_id) {
        Listing storage l = listings[_id];
        require(l.status == Status.Completed, "Task not completed");
        require(!l.paid, "Already paid");

        l.paid = true;
        payable(l.freelancer).transfer(l.price);
        emit PaymentReleased(_id, l.freelancer);
    }

    function raiseDispute(uint256 _id) external onlyInvolved(_id) {
        Listing storage l = listings[_id];
        require(l.status == Status.InProgress || l.status == Status.Completed, "Dispute not applicable");
        l.status = Status.Disputed;
        emit DisputeRaised(_id);
    }
}
