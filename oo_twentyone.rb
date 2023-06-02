module Hand
  def show_cards
    hand.each { |card| puts "[ #{card[0]} of #{card[1]} ]" }
  end

  def display_cards
    puts "#{@name}, you have the following #{hand.count} cards:"
    show_cards
  end

  def adjust_ace(total)
    if total > 21
      hand.select { |card| card[0] == "Ace" }.count.times do
        total -= 10
        break if total <= 21
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
    sum <= 21 ? sum : adjust_ace(sum)
  end

  def busted?
    total_value > 21
  end

  def reset_hand
    @hand = []
  end

  def blackjack?
    @hand.size == 2 && total_value == 21
  end
end

module Promptable
  def continue_any_key
    puts "Press 'Enter' to continue."
    gets.chomp
  end

  def pause
    puts "...Loading...."
    sleep 1
  end

  def pause_longer
    puts "...Loading...."
    sleep 3
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
    puts game_description if input.start_with?("r")
    puts "When you are ready to start the game,"
    continue_any_key if input.start_with?("r")
  end

  def play_again?
    puts ""
    display_tally
    puts "Would you like to play again? \nPress 'Enter' to go again"
    puts "Enter 'e'/'3' to exit"
    response = gets.chomp.downcase
    return true unless response.strip == "e" || response.strip == '3'
  end
end

module Messageable
  def center_form(string)
    puts string.center(30, ":")
  end

  def hit_or_stay_message
    puts "Would you like to hit or stay?"
    puts "Enter 'h'/'1' to Hit or 's'/'2' to Stay"
  end

  def winning_message
    puts "The total value of #{dealer.name} is: #{dealer.total_value}"
    puts "The total value of #{player.name} is: #{player.total_value}"
    puts ""
    busted_message if anyone_busted?
    someone_won
  end

  def busted_message
    puts "#{player.name}, you busted!" if player.busted?
    puts "#{dealer.name} busted." if dealer.busted?
  end

  def reveal_card_message
    clear
    if anyone_busted?
      center_form(" BUSTED! ")
    else
      center_form(" CARD REVEAL ")
    end
    puts ""
    reveal_cards
    pause_longer
  end

  def check_blackjack_message
    if push?
      puts "PUSH!"
    elsif someone_blackjack?
      puts "#{player.name}, YOU HAVE BLACKJACK!" if player.blackjack?
      puts "Dealer has Blackjack" if dealer.blackjack?
      pause_longer
      reveal_card_message
    end
  end

  def player_card_message
    dealer.display_hidden_cards
    puts ""
    player.display_cards
    player.display_total
  end

  def dealer_card_message
    clear
    puts "The Dealer, #{@dealer.name}'s Cards:"
    dealer.show_cards
    dealer.display_total
    puts ""
  end

  def reveal_cards
    center_form(" DEALER'S CARDS ")
    dealer.show_cards
    center_form(" [Total value is: #{dealer.total_value}] ")
    puts ""
    puts "=".center(30, "=")
    puts ""
    center_form(" PLAYER'S CARDS ")
    player.show_cards
    puts ":::: [Total value is: #{player.total_value}] :::: \n\n"
  end

  def display_tally
    center_form(" Game Count ")
    player_score = "#{@player.name} [ #{@player_score} ]"
    dealer_score = "#{@dealer.name} [ #{@dealer_score} ]"
    puts ""
    center_form(" #{player_score} : #{dealer_score} ")
    puts ""
  end

  def display_good_bye_message
    clear
    center_form(" FINAL ")
    display_tally
    center_form(" Thanks for playing! ")
    center_form("")
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
  include Hand
  attr_reader :name, :hand

  def initialize
    @hand = []
    @name = ""
  end

  def add_cards(card)
    @hand += card
  end

  def display_total
    puts "Current Total Value: #{total_value}"
  end
end

class Player < Participant
  def retrieve_name
    loop do
      puts "What is your name?"
      @name = gets.chomp.capitalize
      break unless @name.strip == ""
      puts "That is not a valid name. Please try again."
    end
    puts "Welcome, #{@name}!"
  end
end

class Dealer < Participant
  ROBOTS = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5']

  def retrieve_name
    @name = ROBOTS.sample
    puts "Your dealer for today: #{@name}"
  end

  def display_hidden_cards
    first_card = "[ #{@hand[0][0]} of #{@hand[0][1]} ]"
    puts "#{name} has #{@hand.count} cards."
    @hand.each_index do |index|
      index == 0 ? (puts first_card) : (puts "[ Hidden ]")
    end
  end
end

class TwentyOne
  include Promptable
  include Messageable
  attr_reader :shuffled_deck, :player, :dealer

  def initialize
    @shuffled_deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
    @player_score = 0
    @dealer_score = 0
    @dealer_move = ""
    @player_move = ""
  end

  def reset_game
    @dealer_move = ""
    @player_move = ""
    @shuffled_deck.reset_deck
    player.reset_hand
    dealer.reset_hand
    clear
  end

  def game_description
    <<-DSCRP
      :::::::::::::::::::::::::TWENTY ONE:::::::::::::::::::::::::\n
      Twenty-one is a cardgame played between two participants:
      + Player
      + Dealer\n
      There are two moves the participants can do:
      + Hit:  The party choosing 'Hit' will add a card to their
              Hand from the deck, randomly.
      + Stay: The party choosing 'Stay' indicates that they are
              done adding cards from the deck to their Hand for
              current and all subsequent turns of the game.\n
      Card Values:
      2 - 9 : Cards value is equal to the number on the card.
      Ace   : Card value can equal 11 or 1, depending on whether
              their hand will go over 21.
              (e.g.: A Hand of Two Aces has the value of 22 or 12.
                     Since the goal get 21 or just below, value
                     of 12 is the correct value)
      Face  : Face cards include: Jack, Queen, and King, and are
              valued at 10.\n
      Procedure:
      + Each participant's Hand starts with 2 random cards out of
        a 52-card deck
      + First Turn belongs to the player.
        - As mentioned above, they can choose between two moves:
          'Hit' or 'Stay'
        - If the Player 'Busts' (their Hand's total value over 21)
          after recieving a new card, then they will automatically
          lose, assuming that the Dealer doesn't also 'Bust'.
        - The player's turn is over once they 'Stay'.
      + The Dealer's Turn is next.
        - The dealer must 'Hit' if their Hand's total value is
          less than 17.
        - If the dealer busts, the player wins.
      + Once both dealer and player decides to stay, both Hands
        are revealed.
      + If both Hands have the same total value, its a tie.
      - Otherwise, the Hand's value that is closest to 21, wins!\n
      Good Luck!\n
      ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    DSCRP
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

  def push?
    player.blackjack? && dealer.blackjack?
  end

  def someone_blackjack?
    player.blackjack? || dealer.blackjack?
  end

  def deal_and_add(participant)
    participant.add_cards([shuffled_deck.deal])
  end

  def hit
    puts "Hit!"
    @player_move = "hit"
    deal_and_add(player)
  end

  def stay
    puts "Stay!"
    @player_move = "stay"
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
      puts "That is not a valid response, please enter 'h' or 's'!"
    end
  end

  def dealer_hit_or_stay
    if dealer.total_value < 17
      puts "#{dealer.name} will hit!"
      @dealer_move = "hit"
      deal_and_add(dealer)
    else
      puts "#{dealer.name} stays!"
      @dealer_move = "stay"
    end
  end

  def participants_stay?
    @player_move == "stay" && @dealer_move == "stay"
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

  def someone_won
    if win?(player, dealer)
      puts "#{player.name}, you WIN!"
      @player_score += 1
    elsif win?(dealer, player)
      puts "#{dealer.name} WINS"
      @dealer_score += 1
    else
      puts "Its a TIE!"
    end
  end

  def player_hit_or_stay
    hit_or_stay_message
    hit_stay_response
    pause
  end

  def player_move
    loop do
      @player_move == "stay" ? break : player_card_message
      player_hit_or_stay
      clear
      break if player.busted?
    end
  end

  def dealer_move
    loop do
      @dealer_move == "stay" ? break : dealer_card_message
      dealer_hit_or_stay
      pause
      break if dealer.busted?
    end
  end

  def participants_move
    player_move
    dealer_move unless player.busted?
  end

  def main_game
    loop do
      deal_starting_two
      check_blackjack_message
      participants_move unless someone_blackjack?
      reveal_card_message
      clear
      winning_message
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

=begin
We'll follow our familiar pattern on tackling the OO Twenty-One game:

Write a description of the problem and extract major nouns and verbs.
Make an initial guess at organizing the verbs into nouns and do a spike
to explore the problem with temporary code.

Optional - when you have a better idea of the problem,
model your thoughts into CRC cards.

DESCRIPTION
Twenty-one is a cardgame that is played between two people:
- Player
- Dealer
Each participant is dealt 2 cards out of a 52 card deck
- At this point, the player will take the first turn.
- The player has two moves, 'Hit' or 'Stay'
- Hit involves receiving a card out of the card deck, randomly.
- Stay means that they are done recieving cards from the deck
- after making their move it is now Dealer's Turn
- The dealer must play if their hand is less than 17.
- If the dealer busts, the player wins.
- Once both dealer and player decides to stay, both hands are revealed
- If the cards add up to the same, its a tie.
- Otherwise, whoever has the hand that is closest to 21 wins.

General planning:

NOUNS
Game

Participants
- Player
- Dealer

Hand
- Card
- Total
Deck
- Card

Results
-Win
-Lose
-Tie

VERBS
Deal
Move
- Hit
- Stay
Busts

General Organization of Classes:

Participants
  :hand

  Methods:
  Move
  - Hit
   - random card from deck
  - Stay
   - ends their turn

  Calculate_total
  - needs to access @hand

 < Player
 < Dealer
  def Move
  * for Dealer, if condition, of total < 17, they must hit
end

Deck
  # reusuable class for other cardgames?
includes all 52 cards.
- Reset setting
reset
 - re-creates the original 52 deck card.

Suits
  - Heart
  - Diamond
  - Clubs
  - Spades
Numbers
  Ace -> 1 or 11
  2-9
  Jack -> 10
  King -> 10
  Queen -> 10

  Card will be looking like Deck =
  {["Diamond", 'Ace'] => 1, ... ["Clubs", 'King'] => 10}
  to_s
    Deck.
end

Game
  :Player, :Dealer, :Deck???, :Deal

  initialize
  - Player and Name
  - Dealer
  - Deal each Participant their initial hand.

  play
  -sequences

  results
  - Busted
  - Tie
  - Participant wins (player vs Dealer.)
end

Deck
end
=end
