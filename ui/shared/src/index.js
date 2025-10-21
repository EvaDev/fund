// Export all shared components and utilities
export { default as Sidebar } from './components/Sidebar.jsx';
export { default as InfoCard } from './components/InfoCard.jsx';
export { default as TransactionTable } from './components/TransactionTable.jsx';

// Placeholder wallet context - replace with actual implementation
export const WalletProvider = ({ children }) => children;
export const useWallet = () => ({
  isConnected: false,
  address: null,
  connect: () => {},
  disconnect: () => {}
});

export * from './utils.js';
