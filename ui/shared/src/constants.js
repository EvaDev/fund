// Fund Management Constants
export const FUND_STATUS = {
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  PAUSED: 'paused'
};

export const INVESTMENT_STRATEGIES = {
  CONSERVATIVE: 'conservative',
  MODERATE: 'moderate',
  AGGRESSIVE: 'aggressive',
  CUSTOM: 'custom'
};

export const TOKEN_TYPES = {
  ETH: 'ETH',
  BTC: 'BTC',
  USDC: 'USDC',
  USDE: 'USDE',
  STRK: 'STRK'
};

export const PAYOUT_FREQUENCIES = {
  MONTHLY: 'monthly',
  QUARTERLY: 'quarterly',
  ANNUALLY: 'annually',
  CUSTOM: 'custom'
};

export const TRANSACTION_TYPES = {
  DEPOSIT: 'deposit',
  WITHDRAWAL: 'withdrawal',
  PAYOUT: 'payout',
  INVESTMENT: 'investment',
  DIVIDEND: 'dividend'
};

export const BENEFICIARY_STATUS = {
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  PENDING: 'pending'
};

// UI Constants
export const SIDEBAR_MENU_ITEMS = {
  FUND_MANAGER: [
    { id: 'dashboard', label: 'Dashboard', icon: '📊' },
    { id: 'funds', label: 'My Funds', icon: '💰' },
    { id: 'deposits', label: 'Deposits', icon: '📥' },
    { id: 'investments', label: 'Investments', icon: '📈' },
    { id: 'beneficiaries', label: 'Beneficiaries', icon: '👥' },
    { id: 'payouts', label: 'Payouts', icon: '💸' },
    { id: 'analytics', label: 'Analytics', icon: '📊' },
    { id: 'settings', label: 'Settings', icon: '⚙️' }
  ],
  BENEFICIARY: [
    { id: 'dashboard', label: 'Dashboard', icon: '📊' },
    { id: 'funds', label: 'My Funds', icon: '💰' },
    { id: 'transactions', label: 'Transactions', icon: '📋' },
    { id: 'performance', label: 'Performance', icon: '📈' },
    { id: 'payouts', label: 'Payouts', icon: '💸' },
    { id: 'profile', label: 'Profile', icon: '👤' }
  ]
};

// Contract Addresses (to be updated with actual deployed addresses)
export const CONTRACT_ADDRESSES = {
  FUND: '0x...', // Replace with actual fund contract address
  BENEFICIARY: '0x...', // Replace with actual beneficiary contract address
  INVESTMENT: '0x...', // Replace with actual investment contract address
  PAYOUT: '0x...' // Replace with actual payout contract address
};

// RPC Configuration
export const RPC_CONFIG = {
  MAINNET: 'https://starknet-mainnet.infura.io/v3/YOUR_PROJECT_ID',
  TESTNET: 'https://starknet-sepolia.infura.io/v3/YOUR_PROJECT_ID',
  LOCAL: 'http://localhost:5050'
};

// Default values
export const DEFAULT_VALUES = {
  PING_INTERVAL: 2592000, // 30 days in seconds
  PAYOUT_INTERVAL: 2592000, // 30 days in seconds
  MIN_DEPOSIT: 1000000000000000000, // 1 ETH in wei
  MAX_BENEFICIARIES: 10
};
