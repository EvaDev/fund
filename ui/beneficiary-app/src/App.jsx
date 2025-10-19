import React, { useState, useEffect } from 'react';
import { WalletProvider, useWallet, Sidebar, InfoCard, TransactionTable } from '../../shared/src';
import { 
  formatAddress, 
  formatCurrency, 
  formatTokenAmount,
  loadFromLocalStorage,
  saveToLocalStorage 
} from '../../shared/src/utils';

const BeneficiaryContent = () => {
  const { address, isConnected, connectWallet } = useWallet();
  const [activeItem, setActiveItem] = useState('dashboard');
  const [beneficiaryData, setBeneficiaryData] = useState({
    totalPayouts: 0,
    sharePercentage: 0,
    fundDetails: {
      name: '',
      totalValue: 0,
      manager: '',
      strategy: '',
      performance: 0
    },
    balances: {},
    transactions: [],
    monthlyPayouts: []
  });
  const [isLoading, setIsLoading] = useState(false);

  const handleRefresh = async () => {
    setIsLoading(true);
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000));
    setIsLoading(false);
  };

  const renderDashboard = () => (
    <div className="space-y-8">
      {/* Header */}
      <div className="border-b border-gray-200 pb-6">
        <h1 className="text-2xl font-bold text-gray-800 mb-2">
          Beneficiary Dashboard
        </h1>
        <p className="text-gray-600">
          {isConnected ? `Connected as ${formatAddress(address)}` : 'Not Connected'}
        </p>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Left Column */}
        <div className="space-y-6">
          {/* Fund Information */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-800 mb-4">Fund Information</h3>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-600">Fund Name:</span>
                <span className="font-medium">
                  {beneficiaryData.fundDetails.name || 'Not available'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Total Value:</span>
                <span className="font-medium">
                  {beneficiaryData.fundDetails.totalValue > 0 ? formatCurrency(beneficiaryData.fundDetails.totalValue) : 'Not available'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Your Share:</span>
                <span className="font-medium">
                  {beneficiaryData.sharePercentage > 0 ? `${beneficiaryData.sharePercentage}%` : 'Not set'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Performance:</span>
                <span className="font-medium">
                  {beneficiaryData.fundDetails.performance > 0 ? `${beneficiaryData.fundDetails.performance}%` : 'Not available'}
                </span>
              </div>
            </div>
          </div>

          {/* Account Statistics */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-800 mb-4">Account Statistics</h3>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-600">Total Payouts:</span>
                <span className="font-medium">
                  {beneficiaryData.totalPayouts > 0 ? formatCurrency(beneficiaryData.totalPayouts) : 'No payouts yet'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">This Month:</span>
                <span className="font-medium">Not available</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Last Payout:</span>
                <span className="font-medium">Not available</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Next Payout:</span>
                <span className="font-medium">Not available</span>
              </div>
            </div>
          </div>

          {/* Wallet Information */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-800 mb-4">Wallet Information</h3>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-600">Wallet Address:</span>
                <span className="font-medium">
                  {isConnected ? formatAddress(address) : 'Not connected'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Role:</span>
                <span className="font-medium">Beneficiary</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Network:</span>
                <span className="font-medium">Starknet Testnet</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column */}
        <div className="space-y-6">
          {/* Token Balances */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-800 mb-4">Your Token Balances</h3>
            <div className="space-y-3">
              {Object.keys(beneficiaryData.balances).length > 0 ? (
                Object.entries(beneficiaryData.balances).map(([token, data]) => (
                  <div key={token} className="flex justify-between items-center">
                    <span className="text-gray-600">{token}</span>
                    <div className="text-right">
                      <div className="font-medium">{data.amount} {token}</div>
                      <div className="text-sm text-gray-500">{formatCurrency(data.value)}</div>
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center text-gray-500 py-8">
                  No token balances available
                </div>
              )}
            </div>
          </div>

          {/* Monthly Payouts */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-800 mb-4">Monthly Payouts</h3>
            <div className="space-y-3">
              {beneficiaryData.monthlyPayouts.length > 0 ? (
                beneficiaryData.monthlyPayouts.map((payout, index) => (
                  <div key={index} className="flex justify-between items-center">
                    <div>
                      <div className="font-medium">{payout.month}</div>
                      <div className="text-sm text-gray-500">
                        {payout.tokens.join(', ')}
                      </div>
                    </div>
                    <span className="text-lg font-semibold text-green-600">
                      {formatCurrency(payout.amount)}
                    </span>
                  </div>
                ))
              ) : (
                <div className="text-center text-gray-500 py-8">
                  No payout history available
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Recent Payouts - Full Width */}
      <div className="mt-8">
        <TransactionTable 
          transactions={beneficiaryData.transactions}
          title="Recent Payouts"
        />
      </div>
    </div>
  );

  const renderFunds = () => (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-800">Fund Details</h1>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <InfoCard
          title="Fund Overview"
          data={{
            'Fund Name': beneficiaryData.fundDetails.name,
            'Manager': formatAddress(beneficiaryData.fundDetails.manager),
            'Strategy': beneficiaryData.fundDetails.strategy,
            'Total Value': formatCurrency(beneficiaryData.fundDetails.totalValue),
            'Performance': `${beneficiaryData.fundDetails.performance}%`,
            'Your Share': `${beneficiaryData.sharePercentage}%`
          }}
        />
        
        <InfoCard
          title="Underlying Investments"
          data={{
            'ETH Holdings': '2.5 ETH',
            'BTC Holdings': '0.8 BTC',
            'Stablecoins': '35,000 USDC/USDE',
            'Total Value': formatCurrency(beneficiaryData.fundDetails.totalValue),
            'Last Updated': 'Dec 15, 2024'
          }}
        />
      </div>

      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">Performance Chart</h3>
        <div className="h-64 bg-gray-50 rounded-lg flex items-center justify-center">
          <p className="text-gray-500">Performance chart would be displayed here</p>
        </div>
      </div>
    </div>
  );

  const renderTransactions = () => (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-800">Transaction History</h1>
      
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">Filter Transactions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Token Type
            </label>
            <select className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="">All Tokens</option>
              <option value="ETH">ETH</option>
              <option value="BTC">BTC</option>
              <option value="USDC">USDC</option>
              <option value="USDE">USDE</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Month
            </label>
            <select className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="">All Months</option>
              <option value="2024-12">December 2024</option>
              <option value="2024-11">November 2024</option>
              <option value="2024-10">October 2024</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Status
            </label>
            <select className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="">All Status</option>
              <option value="completed">Completed</option>
              <option value="pending">Pending</option>
              <option value="failed">Failed</option>
            </select>
          </div>
        </div>
      </div>

      <TransactionTable 
        transactions={beneficiaryData.transactions}
        title="All Transactions"
      />
    </div>
  );

  const renderPerformance = () => (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-800">Performance Analytics</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg border border-gray-200 p-6 text-center">
          <div className="text-3xl font-bold text-green-600 mb-2">
            {beneficiaryData.fundDetails.performance}%
          </div>
          <div className="text-gray-600">Total Return</div>
        </div>
        
        <div className="bg-white rounded-lg border border-gray-200 p-6 text-center">
          <div className="text-3xl font-bold text-blue-600 mb-2">
            {formatCurrency(beneficiaryData.totalPayouts)}
          </div>
          <div className="text-gray-600">Total Payouts</div>
        </div>
        
        <div className="bg-white rounded-lg border border-gray-200 p-6 text-center">
          <div className="text-3xl font-bold text-purple-600 mb-2">
            {beneficiaryData.sharePercentage}%
          </div>
          <div className="text-gray-600">Your Share</div>
        </div>
        
        <div className="bg-white rounded-lg border border-gray-200 p-6 text-center">
          <div className="text-3xl font-bold text-orange-600 mb-2">
            {formatCurrency(beneficiaryData.fundDetails.totalValue * beneficiaryData.sharePercentage / 100)}
          </div>
          <div className="text-gray-600">Your Value</div>
        </div>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">Performance Over Time</h3>
        <div className="h-64 bg-gray-50 rounded-lg flex items-center justify-center">
          <p className="text-gray-500">Performance chart would be displayed here</p>
        </div>
      </div>
    </div>
  );

  const renderPayouts = () => (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-800">Payout History</h1>
      
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">Payout Summary</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h4 className="font-medium text-gray-800 mb-3">By Token</h4>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-gray-600">USDC</span>
                <span className="font-medium">{formatCurrency(8000)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">ETH</span>
                <span className="font-medium">{formatCurrency(4000)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">USDE</span>
                <span className="font-medium">{formatCurrency(2000)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">BTC</span>
                <span className="font-medium">{formatCurrency(1000)}</span>
              </div>
            </div>
          </div>
          
          <div>
            <h4 className="font-medium text-gray-800 mb-3">By Month</h4>
            <div className="space-y-2">
              {beneficiaryData.monthlyPayouts.map((payout, index) => (
                <div key={index} className="flex justify-between">
                  <span className="text-gray-600">{payout.month}</span>
                  <span className="font-medium">{formatCurrency(payout.amount)}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <TransactionTable 
        transactions={beneficiaryData.transactions}
        title="Payout History"
      />
    </div>
  );

  const renderProfile = () => (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-800">Profile</h1>
      
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">Beneficiary Information</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Wallet Address
            </label>
            <input
              type="text"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
              value={isConnected ? address : 'Not connected'}
              disabled
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Share Percentage
            </label>
            <input
              type="text"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
              value={`${beneficiaryData.sharePercentage}%`}
              disabled
            />
          </div>
        </div>
      </div>
    </div>
  );

  const renderContent = () => {
    switch (activeItem) {
      case 'dashboard':
        return renderDashboard();
      case 'funds':
        return renderFunds();
      case 'transactions':
        return renderTransactions();
      case 'performance':
        return renderPerformance();
      case 'payouts':
        return renderPayouts();
      case 'profile':
        return renderProfile();
      default:
        return renderDashboard();
    }
  };

  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar
        activeItem={activeItem}
        onItemClick={setActiveItem}
        userType="BENEFICIARY"
        isConnected={isConnected}
        onConnectWallet={connectWallet}
        onRefresh={handleRefresh}
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
      <BeneficiaryContent />
    </WalletProvider>
  );
};

export default App;
