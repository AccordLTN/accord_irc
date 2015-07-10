# deep_dup implementation for Array and Object
class Array
  def deep_dup
    map {|x| x.deep_dup}
  end
end

class Object
  def deep_dup
    dup
  end
end


# Returns true if illegal character found.
def check_character(argument)
  argument.each_char do |s|
    if !(s =~ /[d\d\+-\/*]/)
      return true;
    end
  end
  return false;
end

# Returns true if illegal syntax found.
def check_argument(argument)
  # First character must be a number.
  if argument[0] =~ /\D/
    return true;
  # Two operators in a row is detected.
  elsif argument =~ /[d+\-*\/][d+\-*\/]/
    return true;
  # Illegal characters
  elsif check_character(argument)
    return true;
  else
    return false;
  end
end

# Break a string like "10d6+10/5-4*2" into ["10", "d", "6" ...] etc
def parse_argument (input_string)
  return input_string.split(/([d+\-*\/])/)
end

# This handles repeats and returns array of repeat count and the string - the repeat handler
def repeat_handler(string)
  repeats = 1
  rest_of_string = ""

  string.each_char do |character|
    if character == "#"      
      repeats = string[0..string.index(character)-1]
      rest_of_string = string[string.index(character)+1..string.length]
    end
  end

  return [repeats, rest_of_string]
end 

# Returns array of dice rolls
def roller(die, rep=1)
  return rep.times.map{1 + rand(die)}
end

def sanitize_input(input)
  repetition = 1
  argument_string = input[1]

  # Are there any arguments?
  if input.length < 2
    return "An argument is required."
  end

  # Let's handle repeats first and get their operator out of the way
  # If it has a repeat operator
  # We need to access a global variable here... orz
  if argument_string =~ /\#/
    # That operator must be the first operator, else error.
    if argument_string =~ /^\d*\#/
      temp_array = repeat_handler(argument_string)
      if temp_array[1] =~ /\#/
        return "Two repeat operators? Get out."
      end
      # puts temp_array[0]
      repetition = temp_array[0].to_i
      argument_string = temp_array[1]
    else
      return "Improper repeat operator usage."
    end
  end

  # Are there illegal characters or syntax?
  if check_argument(argument_string)
    return "Illegal character(s) or syntax."
  end

  return [false, argument_string, repetition]
end

# puts sanitize_input("!exa 10d6+10/5-4*2".split)
# puts sanitize_input("!exa 2#10d6+10/5-4*2".split)



# searches array for 'dice' operator, d, then pops out the two adjacent numbers,
# sends them to roller and replaces d with the sum of the roller result
# needs to send the dice array somewhere too...
def roll_handler (math_array, cosmetic_array)
  
  while math_array.include?("d")
    # Get the position of the first d operator
    dice_pos = math_array.index("d")

    # Fetch the number after it and delete it from the array
    dice_faces = math_array.delete_at(dice_pos+1).to_i
    cosmetic_array.delete_at(dice_pos+1)

    # Fetch the number before it and delete it from the array
    dice_repeat = math_array.delete_at(dice_pos-1).to_i
    c_dice_repeat = cosmetic_array.delete_at(dice_pos-1)

    # This changes the d operator position, so change dice_pos too
    dice_pos -= 1

    # Roll the dice, receiving an array of dice values in return
    dice_output = roller(dice_faces, dice_repeat)

    # Now add up the dice values
    dice_sum = 0
    dice_output.each{|x| dice_sum += x}

    # Replace the d operator with the dice sum in the math array
    math_array[dice_pos] = dice_sum.to_s

    # Replace the d operator with the dice output in the cosmetic array
    # If the previous array entry was a dice array, handle it!
    # I don't care how dumb it is, just do it.
    if c_dice_repeat =~ /\)$/
      cosmetic_array[dice_pos] = c_dice_repeat + "d" + dice_faces.to_s + "[" + dice_output.join(",") + "](" + dice_sum.to_s + ")"
    else
      cosmetic_array[dice_pos] = dice_repeat.to_s + "d" + dice_faces.to_s + "[" + dice_output.join(",") + "](" + dice_sum.to_s + ")"
    end
  end

  return [math_array, cosmetic_array]
end

# math_array = ["10", "d", "6", "+", "10", "/", "5", "-", "4", "*", "2"]
# cosmetic_array = ["10", "d", "6", "+", "10", "/", "5", "-", "4", "*", "2"]
# puts math_array
# roll_handler(@math_array,@cosmetic_array)
# puts math_array
# puts cosmetic_array

# Searches array for */ operator, then +- operator, pops out adjacent numbers,
# then performs the respective math before replacing the operator with the new number
def math_handler(math_array)
  # While the math array has * or / operators, solve them left to right.
  
  # while math_array.include?("*") || math_array.include?("/")
  #   # Get the index of the first * operator
  #   mult_pos = math_array.index("*").to_i
  #   div_pos = math_array.index("/").to_i

  #   # So much repeated code, but I kept having strange problems
  #   # without doing it this way.
  #   # TODO: Find a way to not repeat so much code kthx.
  #   if div_pos.nil?
  #     mult_b = math_array.delete_at(mult_pos+1).to_i
  #     mult_a = math_array.delete_at(mult_pos-1).to_i
  #     mult_pos -= 1
  #     # Replace the * operator with the new number
  #     math_array[mult_pos] = (mult_a * mult_b).to_s
  #   elsif mult_pos.nil?
  #     div_b = math_array.delete_at(div_pos+1).to_i
  #     div_a = math_array.delete_at(div_pos-1).to_i
  #     div_pos -= 1
  #     # Replace the / operator with the new number
  #     math_array[math_array.index("/").to_i] = (div_a / div_b).to_s
  #   elsif mult_pos < div_pos
  #     mult_b = math_array.delete_at(mult_pos+1).to_i
  #     mult_a = math_array.delete_at(mult_pos-1).to_i
  #     mult_pos -= 1
  #     # Replace the * operator with the new number
  #     math_array[mult_pos] = (mult_a * mult_b).to_s
  #   elsif div_pos < mult_pos
  #     div_b = math_array.delete_at(div_pos+1).to_i
  #     div_a = math_array.delete_at(div_pos-1).to_i
  #     div_pos -= 1
  #     # Replace the / operator with the new number
  #     math_array[math_array.index("/").to_i] = (div_a / div_b).to_s
  #   end
  # end


# While the math array has * operators, solve them left to right.
  while math_array.include?("*")
    # Get the index of the first * operator
    mult_pos = math_array.index("*").to_i
    mult_b = math_array.delete_at(mult_pos+1).to_i
    mult_a = math_array.delete_at(mult_pos-1).to_i
    mult_pos -= 1
    # Replace the * operator with the new number
    math_array[mult_pos] = (mult_a * mult_b).to_s
  end

  # While the math array has / operators, solve them left to right.
  while math_array.include?("/")
    # Get the index of the first / operator
    div_pos = math_array.index("/").to_i
    div_b = math_array.delete_at(div_pos+1).to_i
    div_a = math_array.delete_at(div_pos-1).to_i
    div_pos -= 1
    # Replace the / operator with the new number
    math_array[math_array.index("/").to_i] = (div_a / div_b).to_s
  end

  # While the math array has + or - operators, solve them left to right.
  while math_array.include?("+") || math_array.include?("-")
    # Get the index of the first + and - operators
    plus_pos = math_array.index("+")
    sub_pos = math_array.index("-")

    # So much repeated code, but I kept having strange problems
    # without doing it this way.
    # TODO: Find a way to not repeat so much code kthx.
    if sub_pos.nil?
      # Get the index of the first + operator
      plus_b = math_array.delete_at(plus_pos+1).to_i
      plus_a = math_array.delete_at(plus_pos-1).to_i
      plus_pos -= 1
      # Replace the + operator with the new number    
      math_array[plus_pos] = (plus_a + plus_b).to_s
    elsif plus_pos.nil?
      sub_b = math_array.delete_at(sub_pos+1).to_i
      sub_a = math_array.delete_at(sub_pos-1).to_i
      sub_pos -= 1
      # Replace the - operator with the new number
      math_array[sub_pos] = (sub_a - sub_b).to_s
    elsif plus_pos < sub_pos
      plus_b = math_array.delete_at(plus_pos+1).to_i
      plus_a = math_array.delete_at(plus_pos-1).to_i
      plus_pos -= 1
      # Replace the + operator with the new number    
      math_array[plus_pos] = (plus_a + plus_b).to_s
    elsif sub_pos < plus_pos
      sub_b = math_array.delete_at(sub_pos+1).to_i
      sub_a = math_array.delete_at(sub_pos-1).to_i
      sub_pos -= 1
      # Replace the - operator with the new number
      math_array[sub_pos] = (sub_a - sub_b).to_s
    end
  end

  # Should be just one number.
  return math_array
end


#math_array = ["10", "+", "6", "+", "10", "/", "5", "-", "4", "*", "2"]
#p math_array.to_s
#p 10 + 6 + 10 / 5 - 4 * 2
#p math_handler(["10", "+", "6", "+", "10", "/", "5", "-", "4", "*", "2"])

#     dice_faces = math_array.delete_at(dice_pos+1).to_i
#     cosmetic_array.delete_at(dice_pos+1)

#     # Fetch the number before it and delete it from the array
#     # This changes dice_pos, so change dice pos too
#     dice_repeat = math_array.delete_at(dice_pos-1).to_i
#     c_dice_repeat = cosmetic_array.delete_at(dice_pos-1)
#     dice_pos -= 1






# MathHandler stuffsssss

#######################
# # While the math array has * operators, solve them left to right.
#   while math_array.include?("*")
#     # Get the index of the first * operator
#     mult_pos = math_array.index("*").to_i
#     mult_b = math_array.delete_at(mult_pos+1).to_i
#     mult_a = math_array.delete_at(mult_pos-1).to_i
#     mult_pos -= 1
#     # Replace the * operator with the new number
#     math_array[mult_pos] = (mult_a * mult_b).to_s
#   end

#   # While the math array has / operators, solve them left to right.
#   while math_array.include?("/")
#     # Get the index of the first / operator
#     div_pos = math_array.index("/").to_i
#     div_b = math_array.delete_at(div_pos+1).to_i
#     div_a = math_array.delete_at(div_pos-1).to_i
#     div_pos -= 1
#     # Replace the / operator with the new number
#     math_array[math_array.index("/").to_i] = (div_a / div_b).to_s
#   end



  # # While the math array has + operators, solve them left to right.
  # while math_array.include?("+")
  #   # Get the index of the first + operator
  #   plus_pos = math_array.index("+")
  #   plus_b = math_array.delete_at(plus_pos+1).to_i
  #   plus_a = math_array.delete_at(plus_pos-1).to_i
  #   plus_pos -= 1
  #   # Replace the + operator with the new number    
  #   math_array[plus_pos] = (plus_a + plus_b).to_s
  # end

  # # While the math array has - operators, solve them left to right.
  # while math_array.include?("-")
  #   # Get the index of the first - operator
  #   sub_pos = math_array.index("-")
  #   sub_b = math_array.delete_at(sub_pos+1).to_i
  #   sub_a = math_array.delete_at(sub_pos-1).to_i
  #   sub_pos -= 1
  #   # Replace the - operator with the new number
  #   math_array[sub_pos] = (sub_a - sub_b).to_s
  # end