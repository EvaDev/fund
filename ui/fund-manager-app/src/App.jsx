import React, { useState, useEffect } from 'react';
import { WalletProvider, useWallet, Sidebar, InfoCard, TransactionTable } from '../../shared/src';
import { 
  formatAddress, 
  formatCurrency, 
  formatTokenAmount,
  loadFromLocalStorage,
  saveToLocalStorage 
} from '../../shared/src/utils';

const FundManagerContent = () => {
  const { address, isConnected, connectWallet } = useWallet();
  const [activeItem, setActiveItem] = useState('dashboard');
  const [fundData, setFundData] = useState({
    totalValue: 0,
    balances: {},
    beneficiaries: [],
    transactions: []
  });
  const [isLoading, setIsLoading] = useState(false);

  const handleRefresh = async () => {
    setIsLoading(true);
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000));
    setIsLoading(false);
  };

  const handleAddFund = () => {
    // Navigate to add fund form
    setActiveItem('funds');
  };

  const renderDashboard = () => (
    <div className="h-full">
      {/* Header */}
      <div className="mb-6 pb-4 border-b border-gray-200">
        <h1 className="text-2xl font-bold text-gray-800 mb-1">
          Fund Manager Dashboard
        </h1>
        <p className="text-gray-600 text-sm">
          {isConnected ? `Connected as ${formatAddress(address)}` : 'Not Connected'}
        </p>
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 h-full">
        {/* Left Column */}
        <div className="space-y-4">
          <div className="bg-white border border-gray-200 rounded-lg p-4">
            <h3 className="font-semibold text-gray-800 mb-3">Fund Information</h3>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-600">Total Value:</span>
                <span className="font-medium">No fund created</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Status:</span>
                <span className="font-medium">Not created</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Created:</span>
                <span className="font-medium">N/A</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Last Updated:</span>
                <span className="font-medium">N/A</span>
              </div>
            </div>
          </div>

          <div className="bg-white border border-gray-200 rounded-lg p-4">
            <h3 className="font-semibold text-gray-800 mb-3">Account Statistics</h3>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-600">Total Deposits:</span>
                <span className="font-medium">N/A</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Active Beneficiaries:</span>
                <span className="font-medium">0</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Total Payouts:</span>
                <span className="font-medium">N/A</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Balance:</span>
                <span className="font-medium">N/A</span>
              </div>
            </div>
          </div>

          <div className="bg-white border border-gray-200 rounded-lg p-4">
            <h3 className="font-semibold text-gray-800 mb-3">Wallet Information</h3>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-600">Wallet Address:</span>
                <span className="font-medium">
                  {isConnected ? formatAddress(address) : 'Not connected'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Role:</span>
                <span className="font-medium">Fund Manager</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Network:</span>
                <span className="font-medium">Starknet Testnet</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column */}
        <div className="space-y-4">
          <div className="bg-white border border-gray-200 rounded-lg p-4">
            <h3 className="font-semibold text-gray-800 mb-3">Token Balances</h3>
            <div className="text-center text-gray-500 py-4 text-sm">
              No token balances available
            </div>
          </div>

          <div className="bg-white border border-gray-200 rounded-lg p-4">
            <h3 className="font-semibold text-gray-800 mb-3">Beneficiaries</h3>
            <div className="text-center text-gray-500 py-4 text-sm">
              No beneficiaries added
            </div>
          </div>
        </div>
      </div>

      {/* Recent Transactions */}
      <div className="mt-6">
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <h3 className="font-semibold text-gray-800 mb-3">Recent Transactions</h3>
          <div className="text-center text-gray-500 py-4 text-sm">
            No transactions found
          </div>
        </div>
      </div>
    </div>
  );

  const renderFunds = () => (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">My Funds</h1>
        <button className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          Create New Fund
        </button>
      </div>
      
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">Fund Details</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Fund Name
            </label>
            <input
              type="text"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Enter fund name"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Investment Strategy
            </label>
            <select className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="conservative">Conservative</option>
              <option value="moderate">Moderate</option>
              <option value="aggressive">Aggressive</option>
              <option value="custom">Custom</option>
            </select>
          </div>
        </div>
      </div>
    </div>
  );

  const renderDeposits = () => (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-800">Deposits</h1>
      
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">Make Deposit</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Token
            </label>
            <select className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="ETH">ETH</option>
              <option value="BTC">BTC</option>
              <option value="USDC">USDC</option>
              <option value="USDE">USDE</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Amount
            </label>
            <input
              type="number"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="0.00"
            />
          </div>
        </div>
        <button className="mt-4 bg-green-600 text-white px-6 py-2 rounded-lg hover:bg-green-700">
          Deposit Funds
        </button>
      </div>
    </div>
  );

  const renderBeneficiaries = () => (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">Beneficiaries</h1>
        <button className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          Add Beneficiary
        </button>
      </div>
      
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">Add New Beneficiary</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Wallet Address
            </label>
            <input
              type="text"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="0x..."
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Share Percentage
            </label>
            <input
              type="number"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="25"
              max="100"
            />
          </div>
        </div>
        <button className="mt-4 bg-green-600 text-white px-6 py-2 rounded-lg hover:bg-green-700">
          Add Beneficiary
        </button>
      </div>
    </div>
  );

  const renderContent = () => {
    switch (activeItem) {
      case 'dashboard':
        return renderDashboard();
      case 'funds':
        return renderFunds();
      case 'deposits':
        return renderDeposits();
      case 'beneficiaries':
        return renderBeneficiaries();
      case 'investments':
        return <div className="text-center py-12"><h1 className="text-2xl font-bold text-gray-800">Investments - Coming Soon</h1></div>;
      case 'payouts':
        return <div className="text-center py-12"><h1 className="text-2xl font-bold text-gray-800">Payouts - Coming Soon</h1></div>;
      case 'analytics':
        return <div className="text-center py-12"><h1 className="text-2xl font-bold text-gray-800">Analytics - Coming Soon</h1></div>;
      case 'settings':
        return <div className="text-center py-12"><h1 className="text-2xl font-bold text-gray-800">Settings - Coming Soon</h1></div>;
      default:
        return renderDashboard();
    }
  };

  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar
        activeItem={activeItem}
        onItemClick={setActiveItem}
        userType="FUND_MANAGER"
        isConnected={isConnected}
        onConnectWallet={connectWallet}
        onRefresh={handleRefresh}
        onAddAction={handleAddFund}
      />
      
      <div className="flex-1 overflow-y-auto">
        <div className="p-6">
          {isLoading ? (
            <div className="flex justify-center items-center h-64">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
            </div>
          ) : (
            renderContent()
          )}
        </div>
      </div>
    </div>
  );
};

const App = () => {
  return (
    <WalletProvider>
      <FundManagerContent />
    </WalletProvider>
  );
};

export default App;
