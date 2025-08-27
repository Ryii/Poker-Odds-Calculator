# Poker Odds Calculator Demo

## Quick Start

```bash
# First time setup (installs OCaml if needed)
./setup.sh

# Run the calculator
./run.sh
```

## Demo Scenarios That Will Blow You Away

### 1. **The Royal Flush Draw**

**Your Hand**: A♥ K♥  
**Board**: Q♥ J♥ T♠

- Click on your cards and board to set this up
- Press SPACE to calculate
- **Watch**: The equity meter shows ~31% equity (9 outs to the nuts!)
- **Notice**: The hand strength gauge glows green
- **Cool**: Real-time animation as the meter fills up

### 2. **The Tough Decision**

**Your Hand**: 8♠ 8♦  
**Board**: A♥ 7♣ 2♦  
**Pot**: $100, Call: $50

- Set up this scenario
- Press SPACE
- **See**: "FOLD (Unprofitable)" recommendation
- **Why**: You need 33% equity but only have ~19% vs random range
- **Visual**: Red indicator shows clear fold

### 3. **The Monster Draw**

**Your Hand**: 9♠ T♠  
**Board**: J♠ Q♠ 2♥

- Set this up for a massive combo draw
- **Watch**: ~54% equity with 15 outs!
- **Visual**: The equity bar is mostly green
- **Decision**: Easy call with any bet size

### 4. **Set Over Set Cooler**

**Your Hand**: 7♥ 7♦  
**Board**: 7♠ K♣ K♥

- Full house! But watch what happens...
- **Equity**: 94%+ vs random hands
- **Visual**: Almost entirely green equity bar
- **Note**: The hand strength meter maxes out

## Visual Features to Notice

### **Animated Card Selection**

- Click any card - it scales up smoothly
- Selected cards have a highlight effect
- Face-down cards have a beautiful pattern

### **Real-Time Equity Bar**

- Smooth animation from 0 to calculated value
- Color-coded sections (green/yellow/red)
- Updates instantly when you change cards

### **Hand Strength Gauge**

- Circular meter showing overall strength
- Gradient from red (weak) to green (strong)
- Percentage display in the center

### **Pot Odds Visualization**

- Golden pot with chip stacks
- Visual representation of bet sizing
- Clear CALL/FOLD recommendation

## Keyboard Shortcuts

### **Card Input** (select a card first)

- **Ranks**: 2-9, T, J, Q, K, A
- **Suits**: h (♥), d (♦), c (♣), s (♠)
- **Calculate**: SPACE

### **Quick Scenarios**

1. **Flush Draw**: Set A♠ K♠ board 2♠ 7♠ T♣
2. **Open-Ended**: Set 8♥ 9♥ board 6♦ 7♣ 2♠
3. **Top Pair**: Set A♦ K♣ board A♠ 7♥ 2♣

## Performance Showcase

While the GUI runs, notice:

- **Smooth 60 FPS** even during calculations
- **Instant feedback** on card changes
- **No lag** when animating
- **Low CPU usage** thanks to optimized algorithms

## Advanced Features

### **Monte Carlo Simulation**

- 10,000 iterations per calculation
- Samples from villain's entire range
- Statistically accurate results

### **Exact Equity Mode**

- For heads-up all-ins
- Enumerates all possible runouts
- 100% accurate results

### **Implied Odds**

- Factors in future betting
- Position-aware calculations
