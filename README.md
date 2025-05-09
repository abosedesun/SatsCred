# SatsCred: Decentralized Reputation Protocol for Bitcoin & Stacks

SatsCred is a **trustless, on-chain reputation management protocol** built on the **Stacks Layer 2** blockchain, designed to bring a robust reputation layer to the **Bitcoin ecosystem**. It leverages **Decentralized Identities (DIDs)** and **verifiable on-chain actions** to calculate, update, and decay reputation scores in a secure, transparent, and decentralized manner.

## Features

* **Decentralized Identity (DID) Support**
  Users establish identities via unique DIDs, stored immutably on-chain.

* **Action-Based Scoring**
  Reputations are influenced by participating in predefined, weighted actions (e.g., governance voting, contract fulfillment, validation).

* **Automated Time-Based Decay**
  Scores decrease over time unless maintained through ongoing activity—discouraging reputation hoarding and incentivizing sustained contribution.

* **Tamper-Proof History Tracking**
  Each reputation change is logged with contextual metadata for full transparency.

* **Permissionless Verification**
  External dApps and smart contracts can read and verify user reputation thresholds for conditional access, trust scoring, and governance logic.

##  Use Cases

* **Web3 Communities & DAOs**: Gate or weight votes based on verifiable reputation.
* **Decentralized Finance (DeFi)**: Use scores as input for collateralization, risk analysis, or access control.
* **On-chain Freelancing & Bounties**: Validate user credibility via historic participation.
* **Proof-of-Participation Systems**: Reward community engagement with tangible reputation gains.

## Contract Summary

| Component                    | Description                                                                          |
| ---------------------------- | ------------------------------------------------------------------------------------ |
| `identities`                 | Stores user identities and associated reputation scores.                             |
| `reputation-actions`         | Defines configurable actions (e.g., "content-creation") and their score multipliers. |
| `reputation-history`         | Logs every reputation change with timestamp and block metadata.                      |
| `decay-rate`, `decay-period` | Adjustable contract variables that control reputation decay logic.                   |

## Key Functions

### Identity Management

```clarity
(create-identity (did (string-ascii 50))) → (ok did) | (err)
(update-identity-status (active bool)) → (ok true) | (err)
```

* Creates a new on-chain identity with a starting reputation.
* Can deactivate/reactivate identities.

### Reputation Scoring

```clarity
(update-reputation-score (action-type (string-ascii 50))) → (ok new-score) | (err)
(decay-reputation) → (ok new-score) | (err)
```

* Updates user scores based on predefined actions.
* Applies decay if the reputation is stale.

### Reputation Queries

```clarity
(get-reputation (owner principal)) → (optional uint)
(get-full-identity (owner principal)) → (optional identity-data)
(verify-reputation (owner principal) (min-threshold uint)) → (optional bool)
(get-reputation-history (owner principal) (tx-id uint)) → (optional record)
```

* Allows any contract or dApp to check user scores or verify if they meet minimum thresholds.

### Admin Controls

```clarity
(set-contract-owner (new-owner principal)) → (ok true) | (err)
(set-contract-active (active bool)) → (ok true) | (err)
(set-decay-parameters (rate uint) (period uint)) → (ok true) | (err)
(add-reputation-action ...) | (update-reputation-action ...) → (ok true) | (err)
```

* Controlled by the contract owner. Admin can enable/disable the protocol, adjust decay logic, and manage action definitions.

## Predefined Reputation Actions

The contract supports these out-of-the-box (can be extended):

| Action Type              | Multiplier | Description                                         |
| ------------------------ | ---------- | --------------------------------------------------- |
| `governance-vote`        | `u5`       | Participation in decentralized governance voting.   |
| `contract-fulfillment`   | `u10`      | Completion of smart contract obligations.           |
| `community-contribution` | `u7`       | Contributions to community-led initiatives.         |
| `validation`             | `u3`       | Verifying transactions or providing data validity.  |
| `content-creation`       | `u6`       | Publishing meaningful content to educate or inform. |

## Security & Anti-Gaming Design

* **Score Cap (`u1000`)**: Prevents reputation inflation.
* **Decay Enforcement**: Stale reputations reduce over time unless maintained.
* **Action Validation**: Only predefined and active actions affect scores.
* **Authorization Checks**: Only identity owners or the admin can mutate relevant data.

## Example Flow

1. A user calls `create-identity` with a valid DID.
2. Participates in a governance vote → `update-reputation-score("governance-vote")`
3. Score increases by `5`, and a log is saved.
4. After the decay period (e.g., 10,000 blocks), score decays by 10%.
5. External dApps can check the user’s current score or require a threshold using `verify-reputation`.

## Contract Parameters

You can view the current configuration with:

```clarity
(get-contract-parameters)
```

Returns:

```clarity
{
  max-reputation: u1000,
  min-reputation: u0,
  starting-reputation: u50,
  decay-rate: u10,
  decay-period: u10000,
  owner: principal,
  active: bool
}
```

## Contributing

We welcome contributions, audits, and community ideas. Open a PR or issue to get involved in shaping trust for decentralized Bitcoin-native applications.
