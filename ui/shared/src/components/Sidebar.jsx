import React from 'react';
import { SIDEBAR_MENU_ITEMS } from '../constants';

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
    <div className="w-64 bg-gray-50 border-r border-gray-200 h-screen flex flex-col">
      {/* Header */}
      <div className="p-6 border-b border-gray-200">
        <h1 className="text-xl font-bold text-gray-800">
          {userType === 'BENEFICIARY' ? 'Beneficiary' : 'Fund Manager'}
        </h1>
      </div>

      {/* Action Buttons */}
      <div className="p-4 space-y-3">
        {!isConnected ? (
          <button
            onClick={onConnectWallet}
            className="w-full bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 transition-colors"
          >
            Connect Wallet
          </button>
        ) : (
          <>
            <button
              onClick={onRefresh}
              className="w-full bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 transition-colors"
            >
              Refresh
            </button>
            {onAddAction && (
              <button
                onClick={onAddAction}
                className="w-full bg-blue-500 text-white py-2 px-4 rounded-lg hover:bg-blue-600 transition-colors"
              >
                Add Fund
              </button>
            )}
          </>
        )}
      </div>

      {/* Navigation Menu */}
      <nav className="flex-1 px-4 py-2">
        <ul className="space-y-1">
          {menuItems.map((item) => (
            <li key={item.id}>
              <button
                onClick={() => onItemClick(item.id)}
                className={`w-full text-left px-4 py-3 rounded-lg transition-colors flex items-center space-x-3 ${
                  activeItem === item.id
                    ? 'bg-gray-200 text-gray-800 font-medium'
                    : 'text-gray-600 hover:bg-gray-100 hover:text-gray-800'
                }`}
              >
                <span className="text-lg">{item.icon}</span>
                <span>{item.label}</span>
              </button>
            </li>
          ))}
        </ul>
      </nav>

      {/* Footer */}
      <div className="p-4 border-t border-gray-200">
        <div className="text-xs text-gray-500 text-center">
          Fund Management System v1.0
        </div>
      </div>
    </div>
  );
};

export default Sidebar;
