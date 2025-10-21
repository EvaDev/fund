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

  // Navigation items
  const navItems = [
    { key: 'dashboard', label: 'Dashboard' },
    { key: 'funds', label: 'Funds' },
    { key: 'beneficiaries', label: 'Beneficiaries' },
    { key: 'investments', label: 'Investments' },
    { key: 'payouts', label: 'Payouts' },
    { key: 'transactions', label: 'Transactions' },
  ];

  const handleNavChange = (key) => {
    setActiveItem(key);
  };

  const renderDashboard = () => (
    <div style={{ padding: '24px', backgroundColor: '#f8f9fa', minHeight: '100vh' }}>
      {/* Header */}
      <div style={{ marginBottom: '32px' }}>
        <h1 style={{ 
          fontSize: '32px', 
          fontWeight: 'bold', 
          color: '#1f2937', 
          marginBottom: '8px',
          margin: 0
        }}>
          Fund Manager Dashboard
        </h1>
        <p style={{ 
          color: '#6b7280', 
          fontSize: '16px',
          margin: 0
        }}>
          {isConnected ? `Connected as ${formatAddress(address)}` : 'Not Connected'}
        </p>
      </div>

      {/* Two Column Layout */}
      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', 
        gap: '24px',
        marginBottom: '32px'
      }}>
        {/* Left Column */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '8px',
            border: '1px solid #e5e7eb',
            padding: '24px'
          }}>
            <h3 style={{ 
              fontSize: '18px', 
              fontWeight: '600', 
              color: '#1f2937', 
              marginBottom: '16px',
              margin: '0 0 16px 0'
            }}>
              Fund Information
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                padding: '8px 0',
                borderBottom: '1px solid #f3f4f6'
              }}>
                <span style={{ color: '#6b7280', fontWeight: '500' }}>Total Value:</span>
                <span style={{ color: '#1f2937', fontWeight: '600' }}>No fund created</span>
              </div>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                padding: '8px 0',
                borderBottom: '1px solid #f3f4f6'
              }}>
                <span style={{ color: '#6b7280', fontWeight: '500' }}>Status:</span>
                <span style={{ color: '#1f2937', fontWeight: '600' }}>Not created</span>
              </div>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                padding: '8px 0',
                borderBottom: '1px solid #f3f4f6'
              }}>
                <span style={{ color: '#6b7280', fontWeight: '500' }}>Created:</span>
                <span style={{ color: '#1f2937', fontWeight: '600' }}>N/A</span>
              </div>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                padding: '8px 0'
              }}>
                <span style={{ color: '#6b7280', fontWeight: '500' }}>Last Updated:</span>
                <span style={{ color: '#1f2937', fontWeight: '600' }}>N/A</span>
              </div>
            </div>
          </div>

          <div style={{
            backgroundColor: 'white',
            borderRadius: '8px',
            border: '1px solid #e5e7eb',
            padding: '24px'
          }}>
            <h3 style={{ 
              fontSize: '18px', 
              fontWeight: '600', 
              color: '#1f2937', 
              marginBottom: '16px',
              margin: '0 0 16px 0'
            }}>
              Account Statistics
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                padding: '8px 0',
                borderBottom: '1px solid #f3f4f6'
              }}>
                <span style={{ color: '#6b7280', fontWeight: '500' }}>Total Deposits:</span>
                <span style={{ color: '#1f2937', fontWeight: '600' }}>N/A</span>
              </div>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                padding: '8px 0',
                borderBottom: '1px solid #f3f4f6'
              }}>
                <span style={{ color: '#6b7280', fontWeight: '500' }}>Active Beneficiaries:</span>
                <span style={{ color: '#1f2937', fontWeight: '600' }}>0</span>
              </div>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                padding: '8px 0',
                borderBottom: '1px solid #f3f4f6'
              }}>
                <span style={{ color: '#6b7280', fontWeight: '500' }}>Total Payouts:</span>
                <span style={{ color: '#1f2937', fontWeight: '600' }}>N/A</span>
              </div>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                padding: '8px 0'
              }}>
                <span style={{ color: '#6b7280', fontWeight: '500' }}>Balance:</span>
                <span style={{ color: '#1f2937', fontWeight: '600' }}>N/A</span>
              </div>
            </div>
          </div>

          <div style={{
            backgroundColor: 'white',
            borderRadius: '8px',
            border: '1px solid #e5e7eb',
            padding: '24px'
          }}>
            <h3 style={{ 
              fontSize: '18px', 
              fontWeight: '600', 
              color: '#1f2937', 
              marginBottom: '16px',
              margin: '0 0 16px 0'
            }}>
              Wallet Information
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                padding: '8px 0',
                borderBottom: '1px solid #f3f4f6'
              }}>
                <span style={{ color: '#6b7280', fontWeight: '500' }}>Wallet Address:</span>
                <span style={{ color: '#1f2937', fontWeight: '600' }}>
                  {isConnected ? formatAddress(address) : 'Not connected'}
                </span>
              </div>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                padding: '8px 0',
                borderBottom: '1px solid #f3f4f6'
              }}>
                <span style={{ color: '#6b7280', fontWeight: '500' }}>Role:</span>
                <span style={{ color: '#1f2937', fontWeight: '600' }}>Fund Manager</span>
              </div>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                padding: '8px 0'
              }}>
                <span style={{ color: '#6b7280', fontWeight: '500' }}>Network:</span>
                <span style={{ color: '#1f2937', fontWeight: '600' }}>Starknet Testnet</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '8px',
            border: '1px solid #e5e7eb',
            padding: '24px'
          }}>
            <h3 style={{ 
              fontSize: '18px', 
              fontWeight: '600', 
              color: '#1f2937', 
              marginBottom: '16px',
              margin: '0 0 16px 0'
            }}>
              Token Balances
            </h3>
            <div style={{ 
              textAlign: 'center', 
              color: '#6b7280', 
              padding: '32px 0'
            }}>
              <div style={{ fontSize: '32px', marginBottom: '8px' }}>💰</div>
              <p style={{ margin: 0 }}>No token balances available</p>
            </div>
          </div>

          <div style={{
            backgroundColor: 'white',
            borderRadius: '8px',
            border: '1px solid #e5e7eb',
            padding: '24px'
          }}>
            <h3 style={{ 
              fontSize: '18px', 
              fontWeight: '600', 
              color: '#1f2937', 
              marginBottom: '16px',
              margin: '0 0 16px 0'
            }}>
              Beneficiaries
            </h3>
            <div style={{ 
              textAlign: 'center', 
              color: '#6b7280', 
              padding: '32px 0'
            }}>
              <div style={{ fontSize: '32px', marginBottom: '8px' }}>👥</div>
              <p style={{ margin: 0 }}>No beneficiaries added</p>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Transactions - Full Width */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '8px',
        border: '1px solid #e5e7eb',
        padding: '24px'
      }}>
        <h3 style={{ 
          fontSize: '18px', 
          fontWeight: '600', 
          color: '#1f2937', 
          marginBottom: '16px',
          margin: '0 0 16px 0'
        }}>
          Recent Transactions
        </h3>
        <div style={{ 
          textAlign: 'center', 
          color: '#6b7280', 
          padding: '32px 0'
        }}>
          <div style={{ fontSize: '32px', marginBottom: '8px' }}>📋</div>
          <p style={{ margin: 0 }}>No transactions found</p>
        </div>
      </div>
    </div>
  );

  const renderFunds = () => (
    <div style={{ padding: '24px', backgroundColor: '#f8f9fa', minHeight: '100vh' }}>
      <h1 style={{ fontSize: '32px', fontWeight: 'bold', color: '#1f2937', marginBottom: '24px' }}>
        My Funds
      </h1>
      <div style={{
        backgroundColor: 'white',
        borderRadius: '8px',
        border: '1px solid #e5e7eb',
        padding: '24px',
        textAlign: 'center'
      }}>
        <p style={{ color: '#6b7280' }}>No funds created yet</p>
      </div>
    </div>
  );

  const renderBeneficiaries = () => (
    <div style={{ padding: '24px', backgroundColor: '#f8f9fa', minHeight: '100vh' }}>
      <h1 style={{ fontSize: '32px', fontWeight: 'bold', color: '#1f2937', marginBottom: '24px' }}>
        Beneficiaries
      </h1>
      <div style={{
        backgroundColor: 'white',
        borderRadius: '8px',
        border: '1px solid #e5e7eb',
        padding: '24px',
        textAlign: 'center'
      }}>
        <p style={{ color: '#6b7280' }}>No beneficiaries added yet</p>
      </div>
    </div>
  );

  const renderInvestments = () => (
    <div style={{ padding: '24px', backgroundColor: '#f8f9fa', minHeight: '100vh' }}>
      <h1 style={{ fontSize: '32px', fontWeight: 'bold', color: '#1f2937', marginBottom: '24px' }}>
        Investments
      </h1>
      <div style={{
        backgroundColor: 'white',
        borderRadius: '8px',
        border: '1px solid #e5e7eb',
        padding: '24px',
        textAlign: 'center'
      }}>
        <p style={{ color: '#6b7280' }}>No investments made yet</p>
      </div>
    </div>
  );

  const renderPayouts = () => (
    <div style={{ padding: '24px', backgroundColor: '#f8f9fa', minHeight: '100vh' }}>
      <h1 style={{ fontSize: '32px', fontWeight: 'bold', color: '#1f2937', marginBottom: '24px' }}>
        Payouts
      </h1>
      <div style={{
        backgroundColor: 'white',
        borderRadius: '8px',
        border: '1px solid #e5e7eb',
        padding: '24px',
        textAlign: 'center'
      }}>
        <p style={{ color: '#6b7280' }}>No payouts scheduled yet</p>
      </div>
    </div>
  );

  const renderTransactions = () => (
    <div style={{ padding: '24px', backgroundColor: '#f8f9fa', minHeight: '100vh' }}>
      <h1 style={{ fontSize: '32px', fontWeight: 'bold', color: '#1f2937', marginBottom: '24px' }}>
        Transactions
      </h1>
      <div style={{
        backgroundColor: 'white',
        borderRadius: '8px',
        border: '1px solid #e5e7eb',
        padding: '24px',
        textAlign: 'center'
      }}>
        <p style={{ color: '#6b7280' }}>No transactions found</p>
      </div>
    </div>
  );

  const renderContent = () => {
    switch (activeItem) {
      case 'dashboard':
        return renderDashboard();
      case 'funds':
        return renderFunds();
      case 'beneficiaries':
        return renderBeneficiaries();
      case 'investments':
        return renderInvestments();
      case 'payouts':
        return renderPayouts();
      case 'transactions':
        return renderTransactions();
      default:
        return renderDashboard();
    }
  };

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      <Sidebar
        activeItem={activeItem}
        onItemClick={handleNavChange}
        userType="FUND_MANAGER"
        isConnected={isConnected}
        onConnectWallet={connectWallet}
        onRefresh={handleRefresh}
        onAddAction={handleAddFund}
      />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        {renderContent()}
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