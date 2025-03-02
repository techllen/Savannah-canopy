import React, { useState } from 'react';
import axios from 'axios';

/**
 * Component to simulate the payment process.
 */
function PaymentComponent() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [message, setMessage] = useState('');

  const processPayment = () => {
    axios.post(`http://localhost:8080/api/payment/checkout?username=${username}&password=${password}`)
      .then(response => {
        setMessage(response.data);
      })
      .catch(error => {
        console.error("Payment processing error", error);
      });
  };

  return (
    <div>
      <h1>Checkout Payment</h1>
      <input type="text" placeholder="Username" onChange={(e) => setUsername(e.target.value)} />
      <input type="password" placeholder="Password" onChange={(e) => setPassword(e.target.value)} />
      <button onClick={processPayment}>Pay Now</button>
      <p>{message}</p>
    </div>
  );
}

export default PaymentComponent;
