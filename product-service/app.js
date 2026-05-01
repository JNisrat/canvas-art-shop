const express = require("express");
const path = require("path");
require("dotenv").config();

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || "http://localhost:3003";

// ─────────────────────────────────────────
// In-memory paintings database
// ─────────────────────────────────────────
const paintings = [
  {
    id: 1,
    title: "Sunset Over the Ocean",
    artist: "Nisrat Jahan",
    price: 250,
    size: '24" x 36"',
    medium: "Oil on Canvas",
    stock: 1,
    image: "/assets/choose/choose-1.png",
    description:
      "A breathtaking sunset with warm golden hues reflecting on calm ocean waters.",
  },
  {
    id: 2,
    title: "Abstract Bloom",
    artist: "Nisrat Jahan",
    price: 180,
    size: '18" x 24"',
    medium: "Acrylic on Canvas",
    stock: 2,
    image: "/assets/choose/choose-2.png",
    description:
      "Bold, expressive floral forms bursting with colour and energy.",
  },
  {
    id: 3,
    title: "Mountain Serenity",
    artist: "Nisrat Jahan",
    price: 320,
    size: '30" x 40"',
    medium: "Oil on Canvas",
    stock: 1,
    image: "/assets/choose/choose-3.png",
    description:
      "Majestic mountain peaks shrouded in morning mist and soft light.",
  },
  {
    id: 4,
    title: "City Lights",
    artist: "Nisrat Jahan",
    price: 210,
    size: '20" x 30"',
    medium: "Acrylic on Canvas",
    stock: 3,
    image: "/assets/choose/choose-4.png",
    description:
      "A vibrant cityscape glowing with the energy of a thousand lights.",
  },
  {
    id: 5,
    title: "Tranquil Forest",
    artist: "Nisrat Jahan",
    price: 290,
    size: '24" x 36"',
    medium: "Watercolour on Canvas",
    stock: 1,
    image: "/assets/choose/choose-5.png",
    description:
      "A peaceful walk through a lush green forest with dappled sunlight.",
  },
  {
    id: 6,
    title: "Red Poppy Fields",
    artist: "Nisrat Jahan",
    price: 160,
    size: '16" x 20"',
    medium: "Oil on Canvas",
    stock: 4,
    image: "/assets/choose/choose-6.png",
    description: "Vivid red poppies swaying gently across an open countryside.",
  },
];

// ─────────────────────────────────────────
// LIST ALL PAINTINGS
// GET /products
// ─────────────────────────────────────────
app.get("/products", (req, res) => {
  res.json(paintings);
});

// ─────────────────────────────────────────
// GET SINGLE PAINTING
// GET /products/:id
// ─────────────────────────────────────────
app.get("/products/:id", (req, res) => {
  const painting = paintings.find((p) => p.id === parseInt(req.params.id));
  if (!painting) {
    return res.status(404).json({ message: "Painting not found" });
  }
  res.json(painting);
});

// ─────────────────────────────────────────
// CART / CHECKOUT UI
// GET /cart
// ─────────────────────────────────────────
app.get("/cart", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "cart.html"));
});

// ─────────────────────────────────────────
// ORDER PROXY (same-origin for browser)
// POST /orders -> forwards to order-service
// GET  /orders -> forwards to order-service
// ─────────────────────────────────────────
app.post("/orders", async (req, res) => {
  try {
    const upstream = await fetch(`${ORDER_SERVICE_URL}/orders`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(req.body),
    });

    const contentType = upstream.headers.get("content-type") || "";
    const body = contentType.includes("application/json")
      ? await upstream.json()
      : await upstream.text();

    res.status(upstream.status);
    if (typeof body === "string") return res.send(body);
    return res.json(body);
  } catch (err) {
    return res.status(502).json({ message: "Could not reach order service" });
  }
});

app.get("/orders", async (req, res) => {
  try {
    const upstream = await fetch(`${ORDER_SERVICE_URL}/orders`);

    const contentType = upstream.headers.get("content-type") || "";
    const body = contentType.includes("application/json")
      ? await upstream.json()
      : await upstream.text();

    res.status(upstream.status);
    if (typeof body === "string") return res.send(body);
    return res.json(body);
  } catch (err) {
    return res.status(502).json({ message: "Could not reach order service" });
  }
});

// ─────────────────────────────────────────
// SERVE UI
// GET /
// ─────────────────────────────────────────
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

// ─────────────────────────────────────────
// START SERVER
// ─────────────────────────────────────────
const PORT = process.env.PORT || 3002;
app.listen(PORT, () => {
  console.log(`Product Service running on port ${PORT}`);
});
