#[starknet::contract]
mod Beneficiary {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointerWriteAccess};

    use crate::shared::{Beneficiary, PayoutPrefs, BeneficiaryAdded, InheritanceTriggered};

    #[storage]
    struct Storage {
        beneficiaries: Map<(ContractAddress, u32), Beneficiary>,  // (owner, index) => Beneficiary
        beneficiary_count: Map<ContractAddress, u32>,  // owner => count
        last_ping: Map<ContractAddress, u64>,  // owner => timestamp
        ping_interval: u64,  // e.g., 30 days in seconds
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BeneficiaryAdded: BeneficiaryAdded,
        InheritanceTriggered: InheritanceTriggered,
    }

    #[constructor]
    fn constructor(ref self: ContractState, ping_interval: u64) {
        self.ping_interval.write(ping_interval);
    }

    #[external(v0)]
    fn add_beneficiary(ref self: ContractState, addr: ContractAddress, share: u8, prefs: PayoutPrefs) {
        let caller = get_caller_address();
        let count = self.beneficiary_count.read(caller);
        
        // Validate shares sum <=100, prefs sum=100
        let mut total_share = 0;
        let mut i = 0;
        while i < count {
            let ben = self.beneficiaries.read((caller, i));
            total_share += ben.share;
            i += 1;
        }
        assert(total_share + share <= 100, 'Shares exceed 100');
        assert(prefs.stable_pct + prefs.bitrefill_pct + prefs.token_pct == 100, 'Prefs not 100');

        self.beneficiaries.write((caller, count), Beneficiary { addr, share, prefs });
        self.beneficiary_count.write(caller, count + 1);

        self.emit(BeneficiaryAdded { owner: caller, beneficiary_addr: addr });
    }

    #[external(v0)]
    fn ping(ref self: ContractState) {
        let caller = get_caller_address();
        self.last_ping.write(caller, get_block_timestamp());
    }

    #[external(v0)]
    fn trigger_claim(ref self: ContractState, owner: ContractAddress) {
        let caller = get_caller_address();
        let last = self.last_ping.read(owner);
        assert(get_block_timestamp() > last + self.ping_interval.read(), 'Not overdue');

        // Find if caller is beneficiary
        let count = self.beneficiary_count.read(owner);
        let mut found = false;
        let mut ben: Beneficiary = Beneficiary { 
            addr: caller, 
            share: 0, 
            prefs: PayoutPrefs { 
                stable_pct: 0, 
                bitrefill_pct: 0, 
                token_pct: 0, 
                token_addr: caller 
            } 
        };
        let mut i = 0;
        while i < count {
            let current_ben = self.beneficiaries.read((owner, i));
            if current_ben.addr == caller {
                found = true;
                ben = current_ben;
                break;
            }
            i += 1;
        }
        assert(found, 'Not a beneficiary');

        // Claim logic: Interact with Fund to transfer share
        // let fund_dispatcher = FundDispatcher { contract_address: /* fund addr */ };  // Hardcode or pass in constructor
        // Calculate share of each token balance
        // For each whitelisted token, transfer (balance * share / 100) to caller, applying prefs (e.g., convert for stables)
        // This needs expansion with DEX calls for conversions; placeholder
        self.emit(InheritanceTriggered { owner, beneficiary_addr: caller });
    }
}