
############
##  RUBY  ##
############

# Open RUBY from a WIN10 shell :
# > irb

# Create string variable, and concatenate :
cadeau = "un bon pour un voyage"
message = "Bravo, tu as recu un " + cadeau + " !" 

# Create a table :
escales = ["Paris", "Toronto", "NYC", "Rio", "Sydney", "Hong-Kong", "Berlin"]
escales.size
escales.reverse
escales[0]
# To add elements to the table :
escales << "Londres"

# Create a hash table (JSON-like) :
hash = {pers1: "Moi", pers2: "Toi", pers3: "Nous"}
hash[:pers2]

# To add or change a record from a hash table :
hash[:pers5] = "Jacqueline"
print(hash)

# FOR loop
jours = ["lundi","mardi","mercredi","jeudi","vendredi"]
i=5
jours.each do |jour|
    if jour == "vendredi" 
        puts jour + " : Bon weekend !"
    elsif jour == "lundi"
        puts jour + " : Bon courage !"
    else
        puts jour + " : Weekend dans #{i} jours !"
    end
    i-=1
end

3.times do |i|
    puts "tourner #{i+1} fois sa langue"
end
puts "... et parler !"

puts

# IF condition
num = 100
if num > 120
    puts "1"
elsif num < 5
    puts "2"
else
    puts "3"
end



