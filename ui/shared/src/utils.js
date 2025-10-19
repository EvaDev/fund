import { RpcProvider, Contract, shortString, uint256, CallData } from 'starknet';
import { CONTRACT_ADDRESSES, RPC_CONFIG } from './constants';

// Utility functions for fund management
export const formatTokenAmount = (amount, decimals = 18) => {
  return (Number(amount) / Math.pow(10, decimals)).toFixed(6);
};

export const parseTokenAmount = (amount, decimals = 18) => {
  return (Number(amount) * Math.pow(10, decimals)).toString();
};

export const formatCurrency = (amount, currency = 'USD') => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency
  }).format(amount);
};

export const formatDate = (timestamp) => {
  return new Date(timestamp * 1000).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

export const formatAddress = (address) => {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
};

// Contract interaction utilities
export const getProvider = (network = 'testnet') => {
  const rpcUrl = RPC_CONFIG[network.toUpperCase()] || RPC_CONFIG.TESTNET;
  return new RpcProvider({ nodeUrl: rpcUrl });
};

export const getContract = (contractName, provider) => {
  const address = CONTRACT_ADDRESSES[contractName.toUpperCase()];
  if (!address) {
    throw new Error(`Contract address not found for ${contractName}`);
  }
  
  // Import ABI based on contract name
  let abi = [];
  // TODO: Add ABI imports when contract ABIs are available
  console.warn(`ABI not found for ${contractName}, using empty ABI`);
  
  return new Contract(abi, address, provider);
};

// Fund management utilities
export const calculateFundValue = (balances, prices) => {
  let totalValue = 0;
  for (const [token, balance] of Object.entries(balances)) {
    const price = prices[token] || 0;
    totalValue += Number(balance) * price;
  }
  return totalValue;
};

export const calculateBeneficiaryShare = (totalValue, sharePercentage) => {
  return (totalValue * sharePercentage) / 100;
};

export const validateAddress = (address) => {
  // Basic Starknet address validation
  return /^0x[0-9a-fA-F]{63,64}$/.test(address);
};

export const validateSharePercentage = (shares) => {
  const total = shares.reduce((sum, share) => sum + share, 0);
  return total <= 100;
};

// API utilities
export const fetchWithRetry = async (url, options = {}, maxRetries = 3) => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url, options);
      if (response.ok) {
        return await response.json();
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
};

export const fetchWithCache = async (url, options = {}, cacheTime = 300000) => {
  const cacheKey = `cache_${url}_${JSON.stringify(options)}`;
  const cached = localStorage.getItem(cacheKey);
  
  if (cached) {
    const { data, timestamp } = JSON.parse(cached);
    if (Date.now() - timestamp < cacheTime) {
      return data;
    }
  }
  
  const data = await fetchWithRetry(url, options);
  localStorage.setItem(cacheKey, JSON.stringify({
    data,
    timestamp: Date.now()
  }));
  
  return data;
};

// Error handling
export const handleContractError = (error) => {
  console.error('Contract error:', error);
  
  if (error.message.includes('insufficient balance')) {
    return 'Insufficient balance for this transaction';
  }
  
  if (error.message.includes('not owner')) {
    return 'You are not authorized to perform this action';
  }
  
  if (error.message.includes('not whitelisted')) {
    return 'This token is not whitelisted';
  }
  
  return 'Transaction failed. Please try again.';
};

// Local storage utilities
export const saveToLocalStorage = (key, data) => {
  try {
    localStorage.setItem(key, JSON.stringify(data));
  } catch (error) {
    console.error('Failed to save to localStorage:', error);
  }
};

export const loadFromLocalStorage = (key, defaultValue = null) => {
  try {
    const item = localStorage.getItem(key);
    return item ? JSON.parse(item) : defaultValue;
  } catch (error) {
    console.error('Failed to load from localStorage:', error);
    return defaultValue;
  }
};

// Debounce utility
export const debounce = (func, wait) => {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
};
