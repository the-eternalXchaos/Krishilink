// This is our "in-memory" database for the example.
// In a real app, this would be a database model (e.g., Sequelize, Mongoose).
const products = [];
let currentId = 1;

class Product {
    constructor(name, price) {
        this.id = currentId++;
        this.name = name;
        this.price = price;
        this.created_at = new Date();
        this.updated_at = new Date();
        this.deleted_at = null; // Key field for soft deletes
    }
}

// Pre-populate with some data for the example
const p1 = new Product('Laptop', 1200);
products.push(p1);

module.exports = { Product, products };
