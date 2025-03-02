import React, { useState } from 'react';
import axios from 'axios';

/**
 * Component for user login, integrating with AWS Cognito (simulated).
 */
function LoginComponent() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [user, setUser] = useState(null);

  const login = () => {
    axios.post('http://localhost:8080/api/auth/login', { username, password })
      .then(response => {
        setUser(response.data);
      })
      .catch(error => {
        console.error("Login error", error);
      });
  };

  return (
    <div>
      <h1>Login</h1>
      <input type="text" placeholder="Username" onChange={(e) => setUsername(e.target.value)} />
      <input type="password" placeholder="Password" onChange={(e) => setPassword(e.target.value)} />
      <button onClick={login}>Login</button>
      {user && <p>Welcome, {user.username}</p>}
    </div>
  );
}

export default LoginComponent;
