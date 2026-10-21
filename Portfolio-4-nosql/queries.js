// MIT 8103 Portfolio 4: MongoDB Queries & Aggregation Pipeline

print("\n--- 1. Filter by Category and Polymorphic Nested Attribute (Phones with RAM >= 8GB) ---");
printjson(
  db.products.find(
    { category: "phones", "attributes.ramGb": { $gte: 8 } },
    { _id: 0, sku: 1, name: 1, price: 1, "attributes.brand": 1, "attributes.ramGb": 1 }
  ).toArray()
);

print("\n--- 2. Full-Text Search on Product Name ('wireless') ---");
printjson(
  db.products.find(
    { $text: { $search: "wireless" } },
    { _id: 0, sku: 1, name: 1, category: 1, price: 1 }
  ).toArray()
);

print("\n--- 3. Aggregation Pipeline: Average Customer Rating & Review Count per Category ---");
printjson(
  db.products.aggregate([
    { $unwind: "$reviews" },
    {
      $group: {
        _id: "$category",
        reviewCount: { $sum: 1 },
        avgRating: { $round: [{ $avg: "$reviews.rating" }, 2] }
      }
    },
    { $sort: { avgRating: -1 } }
  ]).toArray()
);

print("\n--- 4. Verify Index Usage on { category: 1, 'attributes.brand': 1 } ---");
printjson(
  db.products.find({ category: "phones", "attributes.brand": "Samsung" }).explain("executionStats").queryPlanner.winningPlan
);