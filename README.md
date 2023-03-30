# PoolMaximum

## Brief Overview

---

PoolMaximum is a no-loss lottery DeFi protocol that allows users to deposit funds into a pool, those funds will be deposited in a yield aggregator(yearn finance) to earn the highest yield possible and some winners are randomly selected from the pool to receive the interest earned on the deposited funds. 

The above idea is inspired by the PoolTogether protocol but PoolTogether does not maximize the yield earned on the deposited funds. PoolMaximum will be a way to offer a risk-free way for users to earn maximum yields on their deposits.

## Objectives

---

The key features that I am planning to build in this project:

1. (top priority) Build a wrapper contract that takes the deposited funds of all users and deposits them into Yearn Finance Vaults and issues tokens to the user.

2. (less priority) Reward for Participation: PoolMaximum will reward participants who contribute regularly to the prize pool, even if they didn't win in that round. Regular participants will receive points that can be redeemed for prizes.

## Problem it solves

---

PoolMaximum offers a risk-free decentralized way for users to earn maximum yields on their deposits with the following features:

1. Give the users an opportunity to win the maximum possible yield on the pool deposit.
2. Regular participants don’t go empty handed even if they don’t win.
3. Prize draws at PoolMaximum will be transparent: anyone can confirm who won, when, and why.
4. It offers a level playing field where every user enjoys the same conditions.
5. No one but you has access to your deposited funds. Users can redeem their money from the pool at any time.

## High Level Implementation Overview

---

Here’s how the protocol will work(*this is a tentative workflow, and might be modified later*):

1. Participants deposit their funds into a prize pool. 

2. The smart contract then uses the funds to earn interest, which is generated through the yield aggregator - **Yearn Finance.**

3. The interest earned by the prize pool is used to fund prizes. The prizes are distributed to the winners(chosen randomly through **drawings**) through a **Prize distribution system**.

4. Participants who do not win a prize still receive their original deposit back, making PoolMaximum a no-loss prize game.

## Smart contract Architecture and description

---

## Algorithms

---

## Some thoughts and choices I made along the way

---

1. Why am I writing the contracts from scratch and not using pooltogether smart contracts?

2. What algorithm do I use for choosing winner?

3. What algorithm should I use so that no one oges empty handed

## Next Steps

1. Proper commenting of code

2. Algorithm for choosing winner to be improvised

3. Write tests

4. How to test on yearn vault using test eth?

5. 

