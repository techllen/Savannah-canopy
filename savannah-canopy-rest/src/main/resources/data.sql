-- Create the plants table
CREATE TABLE IF NOT EXISTS plants (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    imageurl VARCHAR(255)
);

-- Insert sample data into plants (20 sample rows)
-- All images are provided with a size parameter (?size=200x200) for uniformity.
INSERT INTO plants (name, description, price, imageurl) VALUES
('Aloe Vera', 'A succulent plant known for its medicinal properties.', 15.99, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Strelitzia Reginae', 'Bird of Paradise with vibrant, exotic flowers.', 45.50, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Sansevieria Trifasciata', 'Snake Plant that purifies the air and adds a modern look.', 25.00, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Ficus Sycomorus', 'Sycamore Fig with historical significance and lush foliage.', 35.75, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Dracaena Marginata', 'Madagascar Dragon Tree, ideal for contemporary interiors.', 30.25, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Zamioculcas Zamiifolia', 'ZZ Plant known for its low maintenance and high tolerance.', 28.00, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Haworthia Attenuata', 'Zebra Plant with striking striped leaves, perfect for desks.', 18.50, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Euphorbia Tirucalli', 'Pencil Tree with unique, slender branches and architectural look.', 22.75, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Acacia Nilotica', 'Thorn tree commonly found in African landscapes, symbolizing strength.', 40.00, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Croton Macrostachyus', 'Vibrant foliage with multicolored leaves for a bold statement.', 33.50, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Bauhinia Variegata', 'Orchid Tree with elegant, orchid-like blooms.', 50.00, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Spathodea Campanulata', 'African Tulip Tree with bright red, showy flowers.', 55.00, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Sclerocarya Birrea', 'Marula tree celebrated for its fruit and beneficial oil.', 60.00, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Osteospermum', 'African Daisy with vibrant petals and easy-care nature.', 12.00, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Saintpaulia Ionantha', 'African Violet known for its delicate, charming blooms.', 20.00, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Kalanchoe Blossfeldiana', 'African Kalanchoe, popular for its clusters of small flowers.', 17.50, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Adenium Obesum', 'Impala Lily with a dramatic, swollen stem and striking flowers.', 45.00, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Pittosporum Viridiflorum', 'African Boxwood, a refined ornamental plant for indoor use.', 38.00, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Colocasia Esculenta', 'Elephant Ear, a bold tropical plant for statement interiors.', 30.00, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg'),
('Euphorbia Trigona', 'African Milk Tree with an angular, sculptural form.', 32.50, 'https://m.media-amazon.com/images/I/71uI0j7x9dL._AC_UF1000,1000_QL80_.jpg');