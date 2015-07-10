class Exalted
  include Cinch::Plugin
  require "./lib/accord_helper.rb"
  #require "accord_helper" # doesn't work?
  #attr_accessor :math_array, :cosmetic_array, :repetition

  match /ex/

  def execute(m)
  	input = m.message.split
    response = "#{m.user.nick}: "
    math_array = []
    cosmetic_array = []
    repetition = 1
    double_tens = true
    auto_success = 0
    target_number = 7
    double_custom = false

    # Input sanitation and error checking
    sanitation = sanitize_input(input)
    if sanitation[0] != false
      m.reply response + sanitation
      return 1
    end
    input[1] = sanitation[1]
    repetition = sanitation[2]
	
		# Parsing
    math_array = parse_argument(input[1])
    cosmetic_array = math_array.deep_dup

    # Handle dice rolls if d operators exist
    if math_array.include?("d")
      rolls_handled = roll_handler(math_array, cosmetic_array)
      math_array = rolls_handled[0]
      cosmetic_array = rolls_handled[1]
    end

    # Handle math if */+- operators exist
    if math_array.include?("*") || math_array.include?("/") || math_array.include?("+") || math_array.include?("-")
      math_array = math_handler(math_array)
    end

    # Finally time for exalted specific things

    # !exm disables double_tens
    if input[0] =~ /m/
      double_tens = false
    end

    # !exd adds another number that grants double successes
    if input[0] =~ /d/
      if input[2] =~ /^\d*$/
        double_custom = input[2].to_i
      else
        m.reply response +"Improper use of !exd, pelase provide a target number as the second argument."
        return 1
      end
    end

    # !exs supplies a new target number, should be in input[2] or input[3] if !exd is enabled
    if input[0] =~ /s/ && double_custom != false
      if input[3] =~ /^\d*$/
        target_number = input[3].to_i
      else
        m.reply response + "Improper use of !exds, please provide a double number as the second argument and a target number as the third argument."
        return 1
      end
    elsif input[0] =~ /s/
      if input[2] =~ /^\d*$/
        target_number = input[2].to_i
      else
        m.reply response + "Improper use of !exs, please provide a target number as the second argument."
        return 1
      end
    end

    # Were there any auto-successes/penalties?
    if input[2] =~ /^\+\d*$/
      auto_success = input[2].to_i
    elsif input[3] =~ /^\+\d*$/
      auto_success = input[3].to_i
    elsif input[4] =~ /^\+\d*$/
      auto_success = input[4].to_i
    elsif input[2] =~ /^-\d*$/
      auto_success = -(input[2].to_i)
    elsif input[3] =~ /^-\d*$/
      auto_success = -(input[3].to_i)
    elsif input[4] =~ /^-\d*$/
      auto_success = -(input[4].to_i)
    end

    # Performing Exalted rolls
    roll_array = roller(10, math_array[0].to_i)

    # Totalling successes
    successes = success_count(roll_array, double_tens, auto_success, target_number)

    # Add total rolls to response
    response += "(" + math_array[0].to_s + ") "

    # Add M mode
    if !double_tens
      response += "(M) "
    end

    # Add D mode
    if double_custom != false
      response += "(D" + double_custom.to_s + ") "
    end

    # Add S mode
    if target_number != 7
      response += "(S" + target_number.to_s + ") "
    end

    # Add ordered array to response
    response += roll_array.sort.reverse.join(', ')

    # Add successes to response
    if successes > 0
      response += "    Successes: " + successes.to_s
    else
      response += "  Botch."
    end

    # Add unordered array to response
    response += "        " + roll_array.to_s

    # Send that response!
    m.reply response
	end

  def success_count (roll_array, double_tens = true, auto_success = 0,target_number = 7, double_custom = 10)
    successes = auto_success
    if double_custom == false
      double_custom = 10
    end

    roll_array.each do |x|
      if x.to_i == 10 && double_tens
        successes += 2
      elsif x.to_i == double_custom
        successes += 2
      elsif x.to_i >= target_number
        successes += 1
      end
    end
    return successes
  end

end

# !exam 14+5-2 +2 Someday this will work