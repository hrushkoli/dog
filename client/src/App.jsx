import { useEffect, useState } from "react";
import { ethers } from "ethers";
import contractJson from "./contracts/FreelanceMarketplace.json";

// const CONTRACT_ADDRESS = "0xYourContractAddressHere"; // 🔁 Replace this

function App() {
  const [contract, setContract] = useState(null);
  const [signer, setSigner] = useState(null);
  const [listings, setListings] = useState([]);
  const [form, setForm] = useState({ title: "", description: "", price: "" });

  useEffect(() => {
    const init = async () => {
      if (window.ethereum) {
        const provider = new ethers.BrowserProvider(window.ethereum);
        await window.ethereum.request({ method: "eth_requestAccounts" });
        const _signer = await provider.getSigner();
        const _contract = new ethers.Contract(
          CONTRACT_ADDRESS,
          contractJson.abi,
          _signer
        );

        setSigner(_signer);
        setContract(_contract);
      }
    };
    init();
  }, []);

  const fetchListings = async () => {
    const result = await contract.fetchAllListings();
    setListings(result);
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    const priceInWei = ethers.parseEther(form.price);
    const tx = await contract.setNewListing(
      form.title,
      form.description,
      priceInWei,
      { value: priceInWei }
    );
    await tx.wait();
    setForm({ title: "", description: "", price: "" });
    fetchListings();
  };

  return (
    <div style={{ padding: "2rem" }}>
      <h1>🛠 Freelance Marketplace (Web3 + Vite)</h1>

      <form onSubmit={handleCreate} style={{ marginBottom: "2rem" }}>
        <input
          placeholder="Title"
          value={form.title}
          onChange={(e) => setForm({ ...form, title: e.target.value })}
        />
        <br />
        <textarea
          placeholder="Description"
          value={form.description}
          onChange={(e) => setForm({ ...form, description: e.target.value })}
        />
        <br />
        <input
          placeholder="Price (ETH)"
          value={form.price}
          onChange={(e) => setForm({ ...form, price: e.target.value })}
        />
        <br />
        <button type="submit">Create Listing</button>
      </form>

      <hr />

      <h2>📃 Listings</h2>
      <button onClick={fetchListings}>Load Listings</button>
      {listings.map((l, i) => (
        <div
          key={i}
          style={{ border: "1px solid #aaa", padding: "1rem", margin: "1rem 0" }}
        >
          <p><strong>Title:</strong> {l.title}</p>
          <p><strong>Description:</strong> {l.description}</p>
          <p><strong>Price:</strong> {ethers.formatEther(l.price)} ETH</p>
          <p><strong>Status:</strong> {["Open", "InProgress", "Completed", "Disputed"][l.status]}</p>
        </div>
      ))}
    </div>
  );
}

export default App;
