const express = require("express");
const path = require("path");
require("dotenv").config();

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// ─────────────────────────────────────────
// In-memory orders database
// ─────────────────────────────────────────
const orders = [];

// ─────────────────────────────────────────
// CREATE ORDER
// POST /orders
// Body: { customerName, email, address, items }
// ─────────────────────────────────────────
app.post("/orders", (req, res) => {
  const { customerName, email, address, items } = req.body;

  if (!customerName || !email || !address || !items || items.length === 0) {
    return res.status(400).json({ message: "All fields are required" });
  }

  const total = items.reduce((sum, item) => sum + item.price, 0);

  const newOrder = {
    id: orders.length + 1,
    customerName,
    email,
    address,
    items,
    total,
    status: "confirmed",
    createdAt: new Date().toISOString(),
  };

  orders.push(newOrder);

  res.status(201).json({
    message: "Order placed successfully!",
    order: newOrder,
  });
});

// ─────────────────────────────────────────
// LIST ALL ORDERS
// GET /orders
// ─────────────────────────────────────────
app.get("/orders", (req, res) => {
  res.json(orders);
});

// ─────────────────────────────────────────
// GET SINGLE ORDER
// GET /orders/:id
// ─────────────────────────────────────────
app.get("/orders/:id", (req, res) => {
  const order = orders.find((o) => o.id === parseInt(req.params.id));
  if (!order) {
    return res.status(404).json({ message: "Order not found" });
  }
  res.json(order);
});

// ─────────────────────────────────────────
// SERVE UI
// ─────────────────────────────────────────
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

// ─────────────────────────────────────────
// START SERVER
// ─────────────────────────────────────────
const PORT = process.env.PORT || 3003;
app.listen(PORT, () => {
  console.log(`Order Service running on port ${PORT}`);
});
