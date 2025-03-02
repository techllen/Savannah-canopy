import React, { useEffect, useState } from 'react';
import axios from 'axios';

/**
 * Component to display a list of plant products.
 * 
 * NOTE: Intentional mistake #1 – wrong API endpoint ("api/plant/" instead of "api/plants/").
 */
function ProductComponent() {
  const [products, setProducts] = useState([]);

  const [message, setMessage] = useState('');

  // useEffect(() => {
  //   axios.get('http://localhost:8080/api/plant/')
  //     .then(response => {
  //       setProducts(response.data);
  //     })
  //     .catch(error => {
  //       console.error("Error fetching products", error);
  //     });
  // }, []);

  useEffect(() => {
    axios.get('http://localhost:8080/api/payment/health')
    .then(response => {
      setMessage(response.data.message); // Set the string in state
      console.log(response.data)
    })
    .catch(error => {
      console.error("Error:", error);
    });
},);

return (
  <div>
    <p>Message from API: {message}</p>
  </div>
);
}

export default ProductComponent;