import React from 'react';

const InfoCard = ({ title, data, className = '' }) => {
  return (
    <div className={`bg-white rounded-lg border border-gray-200 p-6 ${className}`}>
      <h3 className="text-lg font-semibold text-gray-800 mb-4">{title}</h3>
      <div className="space-y-3">
        {Object.entries(data).map(([key, value]) => (
          <div key={key} className="flex justify-between items-center">
            <span className="text-gray-600 capitalize">
              {key.replace(/([A-Z])/g, ' $1').trim()}:
            </span>
            <span className="text-gray-800 font-medium">
              {typeof value === 'boolean' ? (value ? 'Yes' : 'No') : value}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default InfoCard;

