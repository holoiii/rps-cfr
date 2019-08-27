#!/usr/bin/env ruby

class RPSTrainer
  attr_accessor :iterations, :player_one, :player_two

  def initialize(iterations)
    self.iterations = iterations

    strategy_one = Strategy.new
    self.player_one = Player.new(strategy_one)

    strategy_two = Strategy.new(4, 3, 3)
    self.player_two = Player.new(strategy_two)
  end

  def run!
    puts "Running for #{iterations} iterations..."
    puts "Player one strategy start: #{player_one.strategy}"
    puts "Player two strategy start: #{player_two.strategy}"

    iterations.times do
      # Get player actions
      action_one = player_one.get_action
      action_two = player_two.get_action

      regret_calculator = RegretCalculator.new(action_one, action_two)

      # Get regrets for player one.
      # Regrets can be negative if we chose the winning action
      rock_regret = regret_calculator.get_rock_regret
      paper_regret = regret_calculator.get_paper_regret
      scissors_regret = regret_calculator.get_scissors_regret

      # puts "Regrets: #{rock_regret}, #{paper_regret}, #{scissors_regret}"

      # Update player one's strategy
      player_one.update_strategy!(rock_regret, paper_regret, scissors_regret)

      # Update player two's strategy
      regret_calculator = RegretCalculator.new(action_two, action_one)
      rock_regret = regret_calculator.get_rock_regret
      paper_regret = regret_calculator.get_paper_regret
      scissors_regret = regret_calculator.get_scissors_regret
      player_two.update_strategy!(rock_regret, paper_regret, scissors_regret)
    end

    puts "Player one strategy end: #{player_one.strategy}"
    puts "Player two strategy end: #{player_two.strategy}"
  end
end

class Strategy
  # Used to generate initial, default strategy
  attr_accessor :num_rock, :num_paper, :num_scissors
  # Used to track regrets over iterations
  attr_accessor :rock_regret, :paper_regret, :scissors_regret
  # Sum, used to calculate average strategy
  attr_accessor :rock_sum, :paper_sum, :scissors_sum

  # Default 33% chance for each action
  def initialize(num_rock = 1, num_paper = 1, num_scissors = 1)
    self.num_rock = num_rock
    self.rock_regret = 0

    self.num_paper = num_paper
    self.paper_regret = 0

    self.num_scissors = num_scissors
    self.scissors_regret = 0

    normalize!

    # This is after normalization (Between 0-100)
    self.rock_sum = self.num_rock
    self.paper_sum = self.num_paper
    self.scissors_sum = self.num_scissors
  end

  # Returns a random action based on the strategy
  def get_action
    random_number = rand * 100.0

    rock_start = 0
    rock_end = self.num_rock

    paper_start = rock_end
    paper_end = paper_start + self.num_paper

    rock_interval = (rock_start..rock_end)
    paper_interval = (paper_start..paper_end)

    if rock_interval.include?(random_number)
      return RockAction.new
    elsif paper_interval.include?(random_number)
      return PaperAction.new
    else
      return ScissorsAction.new
    end
  end

  # IMPORTANT
  # Each iteration basically generates its own strategy based on cumulative regrets

  # Updates the strategy based on regrets
  def update!(rock_regret, paper_regret, scissors_regret)
    # Add all regrets
    self.rock_regret += rock_regret
    self.paper_regret += paper_regret
    self.scissors_regret += scissors_regret

    # Update strategy based on regrets
    self.num_rock = self.rock_regret > 0 ? self.rock_regret : 0
    self.num_paper = self.paper_regret > 0 ? self.paper_regret : 0
    self.num_scissors = self.scissors_regret > 0 ? self.scissors_regret : 0

    # If all of the regrets are non-positive, we should randomize
    if (self.num_rock == 0 && self.num_paper == 0 && self.num_scissors == 0) 
      self.num_rock = 1
      self.num_paper = 1
      self.num_scissors = 1
    end

    normalize!

    self.rock_sum += num_rock
    self.paper_sum += num_paper
    self.scissors_sum += num_scissors
  end

  # Normalizes the strategy to sum to 100
  def normalize!
    total = num_rock + num_paper + num_scissors

    self.num_rock = 100.0 * num_rock / total
    self.num_paper = 100.0 * num_paper / total
    self.num_scissors = 100.0 * num_scissors / total
  end

  def to_s
    # Compute average strategy
    total = rock_sum + paper_sum + scissors_sum
    avg_rock = (rock_sum / total).round(2)
    avg_paper = (paper_sum / total).round(2)
    avg_scissors = (scissors_sum / total).round(2)

    "Rock: #{avg_rock}, Paper: #{avg_paper}, Scissors: #{avg_scissors}"
  end
end

class Action
  def utility_vs_rock
    raise "Implement me"
  end

  def utility_vs_paper
    raise "Implement me"
  end

  def utility_vs_scissors
    raise "Implement me"
  end

  def utility_vs(action)
    if action.is_a?(RockAction)
      utility_vs_rock
    elsif action.is_a?(PaperAction)
      utility_vs_paper
    else
      utility_vs_scissors
    end
  end
end

class RockAction < Action
  def utility_vs_rock
    0
  end
  
  def utility_vs_paper
    -1
  end

  def utility_vs_scissors
    1
  end
end

class PaperAction < Action
  def utility_vs_rock
    1
  end
  
  def utility_vs_paper
    0
  end

  def utility_vs_scissors
    -1
  end
end

class ScissorsAction < Action
  def utility_vs_rock
    -1
  end
  
  def utility_vs_paper
    1
  end

  def utility_vs_scissors
    0
  end
end

class Player
  attr_accessor :strategy

  def initialize(strategy)
    self.strategy = strategy
  end

  # Returns an action based on the player's 
  # current strategy
  def get_action
    strategy.get_action
  end

  def update_strategy!(rock_regret, paper_regret, scissors_regret)
    strategy.update!(rock_regret, paper_regret, scissors_regret)
  end
end

# Calculates regrets from the perspective of the
# first action
class RegretCalculator
  attr_accessor :action_one, :action_two

  def initialize(action_one, action_two)
    self.action_one = action_one
    self.action_two = action_two
  end

  def get_rock_regret
    RockAction.new.utility_vs(action_two) - actual_utility
  end

  def get_paper_regret
    PaperAction.new.utility_vs(action_two) - actual_utility
  end

  def get_scissors_regret
    ScissorsAction.new.utility_vs(action_two) - actual_utility
  end

  def actual_utility
    action_one.utility_vs(action_two)
  end
end

# Run program
trainer = RPSTrainer.new(50000)
trainer.run!
