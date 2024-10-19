# Uniswap V4 Dynamic Fee Hook Smart Contract

The current Uniswap V4 Hook update LP fee dynamicly based on current pool liquidity. The lp fee decreasing from 0.5% to 0.01% during liquidity increasing. Such logic motivates liquidity providers to find liquidity pool faster to receive more fee from start. In the same way it motivates liquidity providers to hold LP tokens longer in case if liquidity decreasing, they will receive more rewards in future. The graph below desrcibe the logic of fee changes.

Plans for development:

- adding support of several formulas for calculation lp fees;
- adding support of AAVE staking;
