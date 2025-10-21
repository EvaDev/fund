import React from 'react';

// Menu items for different user types
const SIDEBAR_MENU_ITEMS = {
  FUND_MANAGER: [
    { id: 'dashboard', label: 'Dashboard', icon: '📊' },
    { id: 'funds', label: 'Funds', icon: '💰' },
    { id: 'beneficiaries', label: 'Beneficiaries', icon: '👥' },
    { id: 'investments', label: 'Investments', icon: '📈' },
    { id: 'payouts', label: 'Payouts', icon: '💸' },
    { id: 'transactions', label: 'Transactions', icon: '📋' }
  ],
  BENEFICIARY: [
    { id: 'dashboard', label: 'Dashboard', icon: '📊' },
    { id: 'funds', label: 'My Funds', icon: '💰' },
    { id: 'payouts', label: 'Payouts', icon: '💸' },
    { id: 'transactions', label: 'History', icon: '📋' }
  ]
};

const Sidebar = ({ 
  activeItem, 
  onItemClick, 
  userType = 'FUND_MANAGER',
  isConnected = false,
  onConnectWallet,
  onRefresh,
  onAddAction
}) => {
  const menuItems = SIDEBAR_MENU_ITEMS[userType] || SIDEBAR_MENU_ITEMS.FUND_MANAGER;

  return (
    <div style={{
      width: '280px',
      backgroundColor: '#f8f9fa',
      borderRight: '1px solid #e5e7eb',
      height: '100vh',
      display: 'flex',
      flexDirection: 'column'
    }}>
      {/* Header */}
      <div style={{
        padding: '24px',
        borderBottom: '1px solid #e5e7eb'
      }}>
        <h1 style={{
          fontSize: '20px',
          fontWeight: 'bold',
          color: '#1f2937',
          margin: 0
        }}>
          {userType === 'BENEFICIARY' ? 'Beneficiary' : 'Fund Manager'}
        </h1>
      </div>

      {/* Action Buttons */}
      <div style={{
        padding: '20px',
        display: 'flex',
        flexDirection: 'column',
        gap: '12px'
      }}>
        {!isConnected ? (
          <button
            onClick={onConnectWallet}
            style={{
              width: '100%',
              backgroundColor: '#10b981',
              color: 'white',
              padding: '12px 16px',
              borderRadius: '8px',
              border: 'none',
              fontSize: '14px',
              fontWeight: '500',
              cursor: 'pointer',
              transition: 'background-color 0.2s'
            }}
            onMouseOver={(e) => e.target.style.backgroundColor = '#059669'}
            onMouseOut={(e) => e.target.style.backgroundColor = '#10b981'}
          >
            Connect Wallet
          </button>
        ) : (
          <>
            <button
              onClick={onRefresh}
              style={{
                width: '100%',
                backgroundColor: '#10b981',
                color: 'white',
                padding: '12px 16px',
                borderRadius: '8px',
                border: 'none',
                fontSize: '14px',
                fontWeight: '500',
                cursor: 'pointer',
                transition: 'background-color 0.2s'
              }}
              onMouseOver={(e) => e.target.style.backgroundColor = '#059669'}
              onMouseOut={(e) => e.target.style.backgroundColor = '#10b981'}
            >
              Refresh
            </button>
            {onAddAction && (
              <button
                onClick={onAddAction}
                style={{
                  width: '100%',
                  backgroundColor: '#3b82f6',
                  color: 'white',
                  padding: '12px 16px',
                  borderRadius: '8px',
                  border: 'none',
                  fontSize: '14px',
                  fontWeight: '500',
                  cursor: 'pointer',
                  transition: 'background-color 0.2s'
                }}
                onMouseOver={(e) => e.target.style.backgroundColor = '#2563eb'}
                onMouseOut={(e) => e.target.style.backgroundColor = '#3b82f6'}
              >
                Add Fund
              </button>
            )}
          </>
        )}
      </div>

      {/* Navigation Menu */}
      <nav style={{
        flex: 1,
        padding: '0 16px 16px 16px'
      }}>
        <ul style={{
          listStyle: 'none',
          padding: 0,
          margin: 0,
          display: 'flex',
          flexDirection: 'column',
          gap: '4px'
        }}>
          {menuItems.map((item) => (
            <li key={item.id} style={{ margin: 0 }}>
              <button
                onClick={() => onItemClick(item.id)}
                style={{
                  width: '100%',
                  textAlign: 'left',
                  padding: '12px 16px',
                  borderRadius: '8px',
                  border: 'none',
                  backgroundColor: activeItem === item.id ? '#e5e7eb' : 'transparent',
                  color: activeItem === item.id ? '#1f2937' : '#6b7280',
                  fontSize: '14px',
                  fontWeight: activeItem === item.id ? '500' : '400',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  transition: 'all 0.2s'
                }}
                onMouseOver={(e) => {
                  if (activeItem !== item.id) {
                    e.target.style.backgroundColor = '#f3f4f6';
                    e.target.style.color = '#1f2937';
                  }
                }}
                onMouseOut={(e) => {
                  if (activeItem !== item.id) {
                    e.target.style.backgroundColor = 'transparent';
                    e.target.style.color = '#6b7280';
                  }
                }}
              >
                <span style={{ fontSize: '16px' }}>{item.icon}</span>
                <span>{item.label}</span>
              </button>
            </li>
          ))}
        </ul>
      </nav>

      {/* Footer */}
      <div style={{
        padding: '16px',
        borderTop: '1px solid #e5e7eb'
      }}>
        <div style={{
          fontSize: '12px',
          color: '#9ca3af',
          textAlign: 'center'
        }}>
          Fund Management System v1.0
        </div>
      </div>
    </div>
  );
};

export default Sidebar;