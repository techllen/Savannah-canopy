import { render, screen } from '@testing-library/react';
import App from '../App';

/**
 * Simple regression test to ensure the app renders the Indoor Plants heading.
 */
test('renders Indoor Plants heading', () => {
  render(<App />);
  const linkElement = screen.getByText(/Indoor Plants/i);
  expect(linkElement).toBeInTheDocument();
});
