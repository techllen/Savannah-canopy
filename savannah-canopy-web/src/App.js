import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import ProductComponent from './components/ProductComponent';
import CartComponent from './components/CartComponent';
import PaymentComponent from './components/PaymentComponent';
import LoginComponent from './components/LoginComponent';

/**
 * Main App component handling routing.
 */
function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<ProductComponent />} />
        <Route path="/cart" element={<CartComponent />} />
        <Route path="/payment" element={<PaymentComponent />} />
        <Route path="/login" element={<LoginComponent />} />
      </Routes>
    </Router>
  );
}

export default App;