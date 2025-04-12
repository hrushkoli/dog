var marketplace = artifacts.require("./FreelanceMarketplace.sol");

module.exports = function(deployer) {
  deployer.deploy(marketplace);
};
