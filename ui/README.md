# Fund Management UI

A React-based frontend for the Fund Management system with two main applications:

- **Fund Manager App** - For fund managers to create funds, manage deposits, set up investment strategies, add beneficiaries, and configure payout schedules
- **Beneficiary App** - For beneficiaries to view their funds, transaction history, fund performance, and payout details

## Project Structure

```
ui/
├── fund-manager-app/     # Fund manager interface
├── beneficiary-app/      # Beneficiary interface
├── shared/              # Shared components and utilities
├── package.json         # Workspace configuration
└── tailwind.config.js   # Tailwind CSS configuration
```

## Features

### Fund Manager App
- **Dashboard**: Overview of fund performance, balances, and beneficiaries
- **Fund Management**: Create and manage multiple funds
- **Deposits**: Deposit various tokens (ETH, BTC, USDC, USDE)
- **Investment Strategies**: Configure investment approaches
- **Beneficiaries**: Add and manage beneficiaries with share percentages
- **Payouts**: Set up and manage payout schedules
- **Analytics**: Performance tracking and reporting
- **Settings**: Account and system configuration

### Beneficiary App
- **Dashboard**: Personal fund overview and recent activity
- **Fund Details**: View underlying investments and performance
- **Transaction History**: Complete payout and transaction history
- **Performance**: Track fund performance and returns
- **Payouts**: Detailed payout history by token and month
- **Profile**: Beneficiary information and settings

## Technology Stack

- **React 19** - Frontend framework
- **Vite** - Build tool and development server
- **Tailwind CSS** - Styling framework
- **Starknet.js** - Blockchain interaction
- **@starknet-io/get-starknet** - Wallet connection

## Getting Started

### Prerequisites

- Node.js 18+ 
- pnpm (recommended) or npm

### Installation

1. Install dependencies for each app:
```bash
cd ui/fund-manager-app
npm install

cd ../beneficiary-app
npm install
```

2. Start development servers:

**Option 1: Start both apps at once:**
```bash
cd ui
./start-apps.sh
```

**Option 2: Start apps individually:**

For Fund Manager App:
```bash
cd ui/fund-manager-app
npm start
```

For Beneficiary App:
```bash
cd ui/beneficiary-app
npm start
```

**To stop the apps:**
```bash
cd ui
./stop-apps.sh
```

### Development

The apps run on different ports:
- Fund Manager App: http://localhost:3001
- Beneficiary App: http://localhost:3002

### Building for Production

```bash
# Build both apps
cd fund-manager-app && pnpm build
cd ../beneficiary-app && pnpm build
```

## Configuration

### Contract Addresses

Update contract addresses in `shared/src/constants.js`:

```javascript
export const CONTRACT_ADDRESSES = {
  FUND: '0x...', // Your deployed fund contract address
  BENEFICIARY: '0x...', // Your deployed beneficiary contract address
  INVESTMENT: '0x...', // Your deployed investment contract address
  PAYOUT: '0x...' // Your deployed payout contract address
};
```

### RPC Configuration

Update RPC endpoints in `shared/src/constants.js`:

```javascript
export const RPC_CONFIG = {
  MAINNET: 'https://starknet-mainnet.infura.io/v3/YOUR_PROJECT_ID',
  TESTNET: 'https://starknet-sepolia.infura.io/v3/YOUR_PROJECT_ID',
  LOCAL: 'http://localhost:5050'
};
```

## Features Overview

### Wallet Integration
- Connect to Starknet wallets
- Display wallet address and connection status
- Handle wallet disconnection

### Fund Management
- Create and manage multiple funds
- Deposit various supported tokens
- Configure investment strategies
- Set up beneficiary distributions

### Beneficiary Features
- View fund performance and holdings
- Track payout history
- Monitor transaction details
- Access fund analytics

### Responsive Design
- Mobile-friendly interface
- Clean, modern UI design
- Consistent styling across apps
- Accessible components

## Customization

### Styling
The apps use Tailwind CSS for styling. Customize the design by modifying:
- `tailwind.config.js` - Theme configuration
- Component styles in individual files
- Shared styles in `shared/src/`

### Components
Shared components are located in `shared/src/components/`:
- `Sidebar` - Navigation sidebar
- `InfoCard` - Information display cards
- `TransactionTable` - Transaction history table

### Utilities
Common utilities are in `shared/src/utils.js`:
- Token amount formatting
- Currency formatting
- Date formatting
- Contract interaction helpers

## Deployment

### Static Hosting
Build the apps and deploy the `dist` folders to any static hosting service:
- Vercel
- Netlify
- AWS S3 + CloudFront
- GitHub Pages

### Docker
Create Dockerfiles for containerized deployment:

```dockerfile
# Example for fund-manager-app
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 3001
CMD ["npm", "run", "serve"]
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
