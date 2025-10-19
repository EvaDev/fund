import React, { createContext, useContext, useState, useEffect } from 'react';
import { connect, disconnect } from '@starknet-io/get-starknet';

const WalletContext = createContext();

export const useWallet = () => {
  const context = useContext(WalletContext);
  if (!context) {
    throw new Error('useWallet must be used within a WalletProvider');
  }
  return context;
};

export const WalletProvider = ({ children }) => {
  const [account, setAccount] = useState(null);
  const [address, setAddress] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState(null);

  const connectWallet = async () => {
    try {
      setIsConnecting(true);
      setError(null);
      
      const starknet = await connect();
      
      if (starknet && starknet.account) {
        setAccount(starknet.account);
        setAddress(starknet.account.address);
        setIsConnected(true);
        
        // Save connection state
        localStorage.setItem('walletConnected', 'true');
        localStorage.setItem('walletAddress', starknet.account.address);
      } else {
        throw new Error('Failed to connect wallet');
      }
    } catch (err) {
      console.error('Wallet connection error:', err);
      setError(err.message || 'Failed to connect wallet');
    } finally {
      setIsConnecting(false);
    }
  };

  const disconnectWallet = async () => {
    try {
      await disconnect();
      setAccount(null);
      setAddress(null);
      setIsConnected(false);
      setError(null);
      
      // Clear connection state
      localStorage.removeItem('walletConnected');
      localStorage.removeItem('walletAddress');
    } catch (err) {
      console.error('Wallet disconnection error:', err);
      setError(err.message || 'Failed to disconnect wallet');
    }
  };

  // Check for existing connection on mount
  useEffect(() => {
    const checkConnection = async () => {
      try {
        const starknet = await connect();
        if (starknet && starknet.account) {
          setAccount(starknet.account);
          setAddress(starknet.account.address);
          setIsConnected(true);
        }
      } catch (err) {
        console.log('No existing wallet connection');
      }
    };

    checkConnection();
  }, []);

  const value = {
    account,
    address,
    isConnected,
    isConnecting,
    error,
    connectWallet,
    disconnectWallet
  };

  return (
    <WalletContext.Provider value={value}>
      {children}
    </WalletContext.Provider>
  );
};
