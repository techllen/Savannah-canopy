import React, { useState } from 'react';
import axios from 'axios';

/**
 * Component to manage the shopping cart.
 */
function CartComponent() {
  const [cart, setCart] = useState(null);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  const addToCart = (product) => {
    axios.post(`http://localhost:8080/api/cart/add?username=${username}&password=${password}`, product)
      .then(response => {
        setCart(response.data);
      })
      .catch(error => {
        console.error("Error adding to cart", error);
      });
  };

  return (
    <div>
      <h1>Your Cart</h1>
      <input type="text" placeholder="Username" onChange={(e) => setUsername(e.target.value)} />
      <input type="password" placeholder="Password" onChange={(e) => setPassword(e.target.value)} />
      {/* Button to simulate adding a dummy product */}
      <button onClick={() => addToCart({ id: 1, name: "Aloe Vera", price: 15.99 })}>Add Aloe Vera</button>
      {cart && (
        <div>
          <h2>Cart Details:</h2>
          {cart.plants && cart.plants.map(item => (
            <div key={item.id}>
              <p>{item.name} - ${item.price}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default CartComponent;
