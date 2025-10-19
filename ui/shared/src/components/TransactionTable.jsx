import React from 'react';
import { formatDate, formatTokenAmount, formatCurrency } from '../utils';

const TransactionTable = ({ transactions, title = 'Transactions' }) => {
  if (!transactions || transactions.length === 0) {
    return (
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">{title}</h3>
        <div className="text-center text-gray-500 py-8">
          No transactions found
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6">
      <h3 className="text-lg font-semibold text-gray-800 mb-4">{title}</h3>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-200">
              <th className="text-left py-3 px-4 font-medium text-gray-600">Date</th>
              <th className="text-left py-3 px-4 font-medium text-gray-600">Type</th>
              <th className="text-left py-3 px-4 font-medium text-gray-600">Token</th>
              <th className="text-left py-3 px-4 font-medium text-gray-600">Amount</th>
              <th className="text-left py-3 px-4 font-medium text-gray-600">Value (USD)</th>
              <th className="text-left py-3 px-4 font-medium text-gray-600">Status</th>
            </tr>
          </thead>
          <tbody>
            {transactions.map((tx, index) => (
              <tr key={index} className="border-b border-gray-100 hover:bg-gray-50">
                <td className="py-3 px-4 text-gray-800">
                  {formatDate(tx.timestamp)}
                </td>
                <td className="py-3 px-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                    tx.type === 'deposit' ? 'bg-green-100 text-green-800' :
                    tx.type === 'withdrawal' ? 'bg-red-100 text-red-800' :
                    tx.type === 'payout' ? 'bg-blue-100 text-blue-800' :
                    'bg-gray-100 text-gray-800'
                  }`}>
                    {tx.type.charAt(0).toUpperCase() + tx.type.slice(1)}
                  </span>
                </td>
                <td className="py-3 px-4 text-gray-800 font-medium">
                  {tx.token}
                </td>
                <td className="py-3 px-4 text-gray-800">
                  {formatTokenAmount(tx.amount, tx.decimals)} {tx.token}
                </td>
                <td className="py-3 px-4 text-gray-800">
                  {formatCurrency(tx.usdValue)}
                </td>
                <td className="py-3 px-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                    tx.status === 'completed' ? 'bg-green-100 text-green-800' :
                    tx.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                    tx.status === 'failed' ? 'bg-red-100 text-red-800' :
                    'bg-gray-100 text-gray-800'
                  }`}>
                    {tx.status.charAt(0).toUpperCase() + tx.status.slice(1)}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default TransactionTable;
