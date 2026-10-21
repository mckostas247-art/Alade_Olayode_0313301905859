// MIT 8103 Portfolio 4: MongoDB Product Catalogue Seed (21 Products across 3 Categories)

db.products.drop();

db.products.insertMany([
  // --- CATEGORY 1: PHONES (8 Documents) ---
  {
    sku: "PHN-001", name: "Samsung Galaxy A55 5G", category: "phones", price: 485000, inStock: true,
    attributes: { brand: "Samsung", ramGb: 8, storageGb: 128, colour: "Black", fiveG: true },
    images: ["phn-001-1.jpg"],
    reviews: [
      { customerId: 12, rating: 5, text: "Great battery and screen", at: ISODate("2026-10-01T10:00:00Z") },
      { customerId: 45, rating: 4, text: "Solid mid-range phone", at: ISODate("2026-10-05T12:00:00Z") }
    ]
  },
  {
    sku: "PHN-002", name: "Samsung Galaxy S24 Ultra", category: "phones", price: 1650000, inStock: true,
    attributes: { brand: "Samsung", ramGb: 12, storageGb: 512, colour: "Titanium Gray", stylus: true },
    images: ["phn-002-1.jpg", "phn-002-2.jpg"],
    reviews: [{ customerId: 88, rating: 5, text: "Best camera zoom on the market", at: ISODate("2026-10-08T09:30:00Z") }]
  },
  {
    sku: "PHN-003", name: "Infinix Note 40 Pro Wireless Edition", category: "phones", price: 365000, inStock: true,
    attributes: { brand: "Infinix", ramGb: 8, storageGb: 256, colour: "Vintage Green", wirelessCharge: true },
    images: ["phn-003-1.jpg"],
    reviews: [{ customerId: 102, rating: 4, text: "Fast wireless MagCharge included", at: ISODate("2026-10-10T15:00:00Z") }]
  },
  {
    sku: "PHN-004", name: "Tecno Camon 30 Premier", category: "phones", price: 590000, inStock: true,
    attributes: { brand: "Tecno", ramGb: 12, storageGb: 512, colour: "Silver", cameraMp: 50 },
    images: ["phn-004-1.jpg"],
    reviews: [{ customerId: 67, rating: 5, text: "Excellent portrait photography", at: ISODate("2026-10-11T11:20:00Z") }]
  },
  {
    sku: "PHN-005", name: "iPhone 16 128GB", category: "phones", price: 1420000, inStock: true,
    attributes: { brand: "Apple", ramGb: 8, storageGb: 128, colour: "Ultramarine", os: "iOS 18" },
    images: ["phn-005-1.jpg"],
    reviews: [{ customerId: 19, rating: 5, text: "Smooth performance and great battery", at: ISODate("2026-10-12T18:00:00Z") }]
  },
  {
    sku: "PHN-006", name: "Xiaomi Redmi Note 13", category: "phones", price: 245000, inStock: false,
    attributes: { brand: "Xiaomi", ramGb: 6, storageGb: 128, colour: "Mint Green" },
    images: ["phn-006-1.jpg"],
    reviews: [{ customerId: 301, rating: 4, text: "Good budget value", at: ISODate("2026-10-14T08:15:00Z") }]
  },
  {
    sku: "PHN-007", name: "Xiaomi POCO X6 Pro", category: "phones", price: 470000, inStock: true,
    attributes: { brand: "Xiaomi", ramGb: 12, storageGb: 512, colour: "Yellow" },
    images: ["phn-007-1.jpg"],
    reviews: [{ customerId: 410, rating: 5, text: "Blazing fast gaming performance", at: ISODate("2026-10-15T19:45:00Z") }]
  },
  {
    sku: "PHN-008", name: "Itel S24 128GB", category: "phones", price: 155000, inStock: true,
    attributes: { brand: "Itel", ramGb: 4, storageGb: 128, colour: "White" },
    images: ["phn-008-1.jpg"],
    reviews: [{ customerId: 509, rating: 3, text: "Decent entry-level backup phone", at: ISODate("2026-10-16T14:10:00Z") }]
  },

  // --- CATEGORY 2: LAPTOPS & AUDIO (7 Documents) ---
  {
    sku: "LAP-001", name: "HP ProBook 450 G9 Core i5", category: "computing", price: 890000, inStock: true,
    attributes: { brand: "HP", cpu: "Intel Core i5-1235U", ramGb: 16, ssdGb: 512, screenInches: 15.6 },
    images: ["lap-001-1.jpg"],
    reviews: [{ customerId: 77, rating: 5, text: "Reliable office workhorse", at: ISODate("2026-10-03T10:00:00Z") }]
  },
  {
    sku: "LAP-002", name: "Dell Vostro 3520 Laptop", category: "computing", price: 750000, inStock: true,
    attributes: { brand: "Dell", cpu: "Intel Core i5-1235U", ramGb: 16, ssdGb: 512, screenInches: 15.6 },
    images: ["lap-002-1.jpg"],
    reviews: [{ customerId: 91, rating: 4, text: "Great keyboard, average display brightness", at: ISODate("2026-10-06T16:30:00Z") }]
  },
  {
    sku: "LAP-003", name: "Apple MacBook Air M3 13-inch", category: "computing", price: 1850000, inStock: true,
    attributes: { brand: "Apple", cpu: "Apple M3", ramGb: 16, ssdGb: 512, screenInches: 13.6 },
    images: ["lap-003-1.jpg"],
    reviews: [{ customerId: 14, rating: 5, text: "15 hours battery life through power outages", at: ISODate("2026-10-09T11:00:00Z") }]
  },
  {
    sku: "LAP-004", name: "Lenovo ThinkPad E14 Gen 5", category: "computing", price: 980000, inStock: true,
    attributes: { brand: "Lenovo", cpu: "AMD Ryzen 7 7730U", ramGb: 16, ssdGb: 1024, screenInches: 14.0 },
    images: ["lap-004-1.jpg"],
    reviews: [{ customerId: 203, rating: 5, text: "Best Linux compatibility and keyboard", at: ISODate("2026-10-12T13:20:00Z") }]
  },
  {
    sku: "AUD-001", name: "Sony WH-1000XM5 Wireless Noise Cancelling Headphones", category: "computing", price: 460000, inStock: true,
    attributes: { brand: "Sony", wireless: true, anc: true, batteryHours: 30, colour: "Black" },
    images: ["aud-001-1.jpg"],
    reviews: [{ customerId: 33, rating: 5, text: "Blocks generator noise completely", at: ISODate("2026-10-15T17:00:00Z") }]
  },
  {
    sku: "AUD-002", name: "Oraimo FreePods 4 Wireless Earbuds", category: "computing", price: 38000, inStock: true,
    attributes: { brand: "Oraimo", wireless: true, anc: true, batteryHours: 35, colour: "Black" },
    images: ["aud-002-1.jpg"],
    reviews: [{ customerId: 155, rating: 4, text: "Awesome bass for the price", at: ISODate("2026-10-17T09:40:00Z") }]
  },
  {
    sku: "LAP-005", name: "Logitech MX Master 3S Wireless Mouse", category: "computing", price: 135000, inStock: true,
    attributes: { brand: "Logitech", wireless: true, dpi: 8000, rechargeable: true },
    images: ["lap-005-1.jpg"],
    reviews: [{ customerId: 88, rating: 5, text: "Ergonomic perfection for coding", at: ISODate("2026-10-19T14:00:00Z") }]
  },

  // --- CATEGORY 3: FASHION & APPAREL (6 Documents) ---
  {
    sku: "FSH-001", name: "Classic Senator Native Wear", category: "fashion", price: 45000, inStock: true,
    attributes: { brand: "LagosTailor", size: "XL", colour: "Royal Blue", fabric: "Cashmere" },
    images: ["fsh-001-1.jpg"],
    reviews: [{ customerId: 400, rating: 5, text: "Perfect fit and clean stitching", at: ISODate("2026-10-04T08:00:00Z") }]
  },
  {
    sku: "FSH-002", name: "Adire Silk Kampal Boubou Gown", category: "fashion", price: 38000, inStock: true,
    attributes: { brand: "AbeokutaCrafts", size: "Free Size", colour: "Indigo", fabric: "Silk Adire" },
    images: ["fsh-002-1.jpg"],
    reviews: [{ customerId: 412, rating: 5, text: "Vibrant hand-dyed pattern", at: ISODate("2026-10-07T10:30:00Z") }]
  },
  {
    sku: "FSH-003", name: "Men's Leather Oxford Formal Shoes", category: "fashion", price: 62000, inStock: true,
    attributes: { brand: "AbaMadePro", shoeSizeEu: 43, colour: "Dark Brown", material: "Genuine Leather" },
    images: ["fsh-003-1.jpg"],
    reviews: [{ customerId: 210, rating: 4, text: "Sturdy sole and rich leather finish", at: ISODate("2026-10-11T15:45:00Z") }]
  },
  {
    sku: "FSH-004", name: "Ankara Corporate Blazer Jacket", category: "fashion", price: 52000, inStock: true,
    attributes: { brand: "LagosTailor", size: "M", colour: "Multi", fabric: "Cotton Ankara" },
    images: ["fsh-004-1.jpg"],
    reviews: [{ customerId: 318, rating: 4, text: "Stylish Friday office wear", at: ISODate("2026-10-14T12:15:00Z") }]
  },
  {
    sku: "FSH-005", name: "Women's Strappy Heel Sandals", category: "fashion", price: 29000, inStock: false,
    attributes: { brand: "EleganceNG", shoeSizeEu: 39, heelHeightCm: 7, colour: "Gold" },
    images: ["fsh-005-1.jpg"],
    reviews: [{ customerId: 501, rating: 3, text: "Looks great but straps run slightly tight", at: ISODate("2026-10-18T16:00:00Z") }]
  },
  {
    sku: "FSH-006", name: "Unisex Cotton Polo Shirt", category: "fashion", price: 18000, inStock: true,
    attributes: { brand: "NaijaBasics", size: "L", colour: "Forest Green", fabric: "100% Pique Cotton" },
    images: ["fsh-006-1.jpg"],
    reviews: [{ customerId: 602, rating: 4, text: "Breathable fabric for humid weather", at: ISODate("2026-10-21T11:10:00Z") }]
  }
]);

// Create compound index on category + nested attributes.brand, and a text index on name
db.products.createIndex({ category: 1, "attributes.brand": 1 });
db.products.createIndex({ name: "text" });

print("Inserted documents count: " + db.products.countDocuments());