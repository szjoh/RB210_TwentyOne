MIN_HAND = 17
MAX_HAND = 21
STARTING_HAND = 2

module Hand
  SUIT_SYMBOL = { "Hearts" => "♥", "Diamonds" => "♦", "Spades" => "♠",
                  "Clubs" => "♣", "HIDDEN" => "[HIDDEN]" }

  def card_illustration(card)
    <<-CARD_DISPLAY
    .............
    :           :
    :  #{card[0].to_s[0]}        :
    :           :
    :#{SUIT_SYMBOL[card[1]].center(11, ' ')}:
    :           :
    :        #{card[0].to_s[0]}  :
    :           :
    :...........:
    CARD_DISPLAY
  end

  def illustrate_cards
    card_array = []
    hand.each do |card|
      card_array << card_illustration(card).lines
    end
    new_arr = card_array.transpose.map!(&:flatten)
    new_arr.each do |lines|
      lines.each_cons(hand.size) { |cards| puts cards.map(&:chomp).join }
    end
    puts "\n"
  end

  def illustrate_hidden_cards(hidden_hand)
    card_array = []
    hidden_hand.each do |card|
      card_array << card_illustration(card).lines
    end
    new_arr = card_array.transpose.map!(&:flatten)
    new_arr.each do |lines|
      lines.each_cons(hidden_hand.size) do |cards|
        puts cards.map(&:chomp).join
      end
    end
  end

  def display_cards
    puts "#{@name}, you have the following #{hand.count} cards:\n\n"
    illustrate_cards
  end

  def adjust_ace(total)
    if total > MAX_HAND
      hand.select { |card| card[0] == "Ace" }.count.times do
        total -= 10
        break if total <= MAX_HAND
      end
    end
    total
  end

  def face_to_value(face)
    case face
    when "King", "Queen", "Jack"
      10
    when "Ace"
      11
    else
      face.to_i
    end
  end

  def total_value
    faces_and_numbers = hand.map { |card| card[0] }
    values = faces_and_numbers.map { |face| face_to_value(face) }
    sum = values.sum
    sum <= MAX_HAND ? sum : adjust_ace(sum)
  end

  def busted?
    total_value > MAX_HAND
  end

  def reset_hand
    @hand = []
  end

  def blackjack?
    @hand.size == STARTING_HAND && total_value == MAX_HAND
  end
end

module Promptable
  def continue_any_key
    puts "Press 'Enter' to continue."
    gets.chomp
  end

  def pause
    puts "...Loading...."
    sleep 1.5
  end

  def pause_longer
    puts "...Loading...."
    sleep 2.5
  end

  def clear
    system 'clear'
    puts ""
  end

  def welcome_prompt
    puts "Hello! Welcome to Twenty-One!"
    puts "Would you like to review the rules before you play?"
    puts "Please input 'r' for review"
    puts "OR \n'Enter' to continue to the game!"
    input = gets.chomp.downcase
    puts File.read("21_game_rules.txt") if input.start_with?("r")
    continue_any_key if input.start_with?("r")
  end
end

module Messageable
  def max_format_size
    sizes = [player.hand.size, dealer.hand.size]
    18 * sizes.max
  end

  def center_form(string, border)
    add_size = player.name.length
    puts string.center(max_format_size + add_size, border)
  end

  def hit_or_stay_message
    puts "Would you like to hit or stay?"
    puts "Enter 'h'/'1' to Hit or 's'/'2' to Stay"
  end

  def game_summary_message
    busted_message if anyone_busted?
    center_form("#{dealer.name}'s total value is: #{dealer.total_value}", " ")
    center_form("#{player.name}'s total value is: #{player.total_value}", " ")
    puts ""
  end

  def busted_message
    center_form("#{player.name}, you busted!", " ") if player.busted?
    center_form("#{dealer.name} busted.", " ") if dealer.busted?
  end

  def check_blackjack_message
    if push?
      clear
      puts "PUSH!"
    elsif someone_blackjack?
      clear
      puts "#{player.name}, YOU HAVE BLACKJACK!" if player.blackjack?
      puts "Dealer has Blackjack" if dealer.blackjack?
      pause_longer
    end
  end

  def center_message
    if anyone_busted?
      center_form(" BUSTED! ", " ")
    else
      center_form(" CARD REVEAL ", " ")
    end
  end

  def reveal_card_message
    clear
    puts ""
    reveal_cards
    continue_any_key
  end

  def reveal_cards
    center_form(" DEALER'S CARDS ", "=")
    dealer.illustrate_cards
    center_form(" [Total value is: #{dealer.total_value}] ", "=")
    puts ""
    center_message
    puts ""
    center_form(" PLAYER'S CARDS ", "=")
    player.illustrate_cards
    center_form(" [Total value is: #{player.total_value}] ", "=")
    puts ""
  end

  def display_tally
    center_form(" Game Score ", " ")
    player_score = "#{@player.name} [ #{player.score} ]"
    dealer_score = "#{@dealer.name} [ #{dealer.score} ]"
    puts ""
    center_form(" #{dealer_score} : #{player_score} ", ":")
    puts ""
  end

  def play_again_message
    center_form("Would you like to play again?", " ")
    center_form("Press 'Enter' to go again", " ")
    center_form("Enter 'e'/'3' to exit", " ")
    puts ""
    center_form(":", ":")
  end

  def display_good_bye_message
    clear
    center_form(":", ":")
    puts " "
    center_form(" Final ", " ")
    display_tally
    center_form(" Thanks for playing! ", " ")
    puts " "
    center_form(":", ":")
  end
end

class Deck
  attr_reader :deck

  SUITS = ["Hearts", "Diamonds", "Spades", "Clubs"]

  FACES = ["Ace", ("2".."9").to_a, "Jack", "Queen", "King"].flatten

  def initialize
    reset_deck
  end

  def reset_deck
    @deck = []
    SUITS.each { |suite| FACES.each { |face| deck << [face, suite] } }
    shuffle!
  end

  def shuffle!
    deck.shuffle!
  end

  def deal
    deck.pop
  end
end

class Participant
  include Messageable
  include Promptable
  include Hand
  attr_reader :name, :hand, :score
  attr_accessor :move

  def initialize
    @hand = []
    @name = ""
    @score = 0
    @move = "hit"
  end

  def reset_hand
    @hand = []
    @move = "hit"
  end

  def add_cards(card)
    @hand += card
  end

  def display_total
    puts "Current Total Value: #{total_value}"
  end

  def make_move(card)
    case move
    when "stay"
      stay
    when "hit"
      hit_or_stay
      add_cards(card) if move == "hit"
    end
  end

  def hit
    puts "#{@name} HITS!"
    @move = 'hit'
    pause
  end

  def stay
    puts "#{@name} STAYS!"
    @move = 'stay'
    pause
  end

  def add_score
    @score += 1
  end
end

class Player < Participant
  def retrieve_name
    loop do
      puts "What is your name?"
      @name = gets.chomp.strip.capitalize
      break unless @name.strip == ""
      puts "That is not a valid name. Please try again."
    end
    puts "Welcome, #{@name}!"
  end

  def card_message
    puts ""
    display_cards
    display_total
  end

  def valid_hit_stay?(response)
    response == "1" ||
      response == "2" ||
      response.start_with?('h') ||
      response.start_with?('s')
  end

  def hit_stay_response
    loop do
      response = gets.chomp.downcase
      if response == '1' || response.start_with?('h')
        hit
      elsif response == '2' || response.start_with?('s')
        stay
      end
      break if valid_hit_stay?(response)
      puts "That is not a valid response, please enter 'h'/'1' or 's'/'2'!"
    end
  end

  def hit_or_stay
    card_message
    hit_or_stay_message
    hit_stay_response
    clear
  end
end

class Dealer < Participant
  ROBOTS = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5']

  def retrieve_name
    @name = ROBOTS.sample
    puts "Your dealer for today: #{@name}"
  end

  def display_hidden_cards
    hidden_hand = [@hand[0], [" ", "HIDDEN"]]
    puts "#{name} has #{@hand.count} cards."
    illustrate_hidden_cards(hidden_hand)
  end

  def hit_or_stay
    if hand.size == STARTING_HAND
      pause
    end
    card_message
    if total_value < MIN_HAND
      hit
    else
      stay
    end
  end

  def card_message
    clear
    puts "The Dealer, #{@name}'s Cards:"
    illustrate_cards
    display_total
    puts ""
  end
end

class TwentyOne
  include Promptable
  include Messageable
  attr_reader :player, :dealer
  attr_accessor :shuffled_deck

  def initialize
    @shuffled_deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
  end

  def reset_game
    @shuffled_deck.reset_deck
    player.reset_hand
    dealer.reset_hand
    clear
  end

  def retrieve_names
    player.retrieve_name
    dealer.retrieve_name
    continue_any_key
    clear
  end

  def deal_first_cards(participant)
    new_cards = []
    new_cards << @shuffled_deck.deal << @shuffled_deck.deal
    participant.add_cards(new_cards)
  end

  def deal_starting_two
    deal_first_cards(player)
    deal_first_cards(dealer)
  end

  def deal_and_add(participant)
    participant.add_cards([shuffled_deck.deal])
  end

  def push?
    player.blackjack? && dealer.blackjack?
  end

  def someone_blackjack?
    player.blackjack? || dealer.blackjack?
  end

  def participants_stay?
    player.move == "stay" && dealer.move == "stay"
  end

  def anyone_busted?
    player.busted? || dealer.busted?
  end

  def everyone_busted?
    player.busted? && dealer.busted?
  end

  def win?(party, other_party)
    return false if party.busted?
    party.total_value > other_party.total_value ||
      other_party.busted?
  end

  def tally_winner
    if win?(player, dealer)
      center_form("#{player.name}, you WIN!", " ")
      player.add_score
    elsif win?(dealer, player)
      center_form("#{dealer.name} WINS", " ")
      dealer.add_score
    else
      center_form("Its a TIE!", " ")
    end
  end

  def hit_loop(participant)
    loop do
      dealer.display_hidden_cards if dealer.hand.size == STARTING_HAND
      participant.make_move([shuffled_deck.deal])
      break if participant.move == "stay" || participant.busted?
    end
  end

  def participants_move
    clear
    hit_loop(player)
    hit_loop(dealer) unless player.busted?
  end

  def play_again?
    clear
    puts center_form(":", ":")
    tally_winner
    game_summary_message
    puts ""
    display_tally
    play_again_message
    response = gets.chomp.downcase
    return true unless response.strip == "e" || response.strip == '3'
  end

  def main_game
    loop do
      deal_starting_two
      check_blackjack_message
      participants_move unless someone_blackjack?
      reveal_card_message
      break unless play_again?
      reset_game
    end
  end

  def play
    welcome_prompt
    retrieve_names
    main_game
    display_good_bye_message
  end
end

game = TwentyOne.new

game.play
