import { render, screen } from '@testing-library/react';
import ProductComponent from '../components/ProductComponent';

/**
 * Test to check if the ProductComponent renders correctly.
 */
test('renders product component', () => {
  render(<ProductComponent />);
  const headingElement = screen.getByText(/Indoor Plants/i);
  expect(headingElement).toBeInTheDocument();
});