# Use a lightweight base image with Node.js and npm
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to install dependencies
COPY package*.json ./

# Install project dependencies
RUN npm install

# Copy the rest of the application source code
COPY . .

# Build the React app
RUN npm run build

# Expose the port your React app will run on (usually 3000)
EXPOSE 3000

# Start the React app
CMD ["npm", "start"]