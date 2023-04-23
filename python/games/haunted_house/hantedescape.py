# Import any required modules
# The random module is being used to randomly assign where the key, trap door and escape room are.
# See, for example, https://www.w3schools.com/python/python_random.asp
import random

# Define accepted genders in a list
# A list is a data structure available in Python to store multiple values in a single variable.
# See, for example, https://www.w3schools.com/python/python_lists.asp

genders = ["male", "female", "non-binary", "other"]

# Define the rooms and their connections into a dictionary, this should allow adding rooms and connections easily.
# A dictionary is a Python data structure made up of key-value pairs.
# See, for example, https://www.w3schools.com/python/python_dictionaries.asp
# or https://www.tutorialspoint.com/python_data_structure/python_data_structure_introduction.htm

# Page 19 and 20 - Here's a description of the house and room layout.
# Foyer: The foyer is the starting point of the game. From here, you can go forward to the dining room, right to the study, back to the living room, or left to the bathroom.
# Living room: From the living room, you can go forward to the foyer, right to the kitchen, back to the garden, or left to the library.
# Dining room: From the dining room, you can go back to the foyer, right to the kitchen, forward to the patio, or take the secret passage to the bedroom.
# Kitchen: From the kitchen, you can go left to the living room, forward to the dining room, right to the pantry, or descend to the basement.
# Library: From the library, you can go right to the living room, forward to the study, back to the bathroom, or take the secret passage to the bedroom.
# Study: From the study, you can go left to the foyer, forward to the basement, back to the library, or right to the bathroom.
# Bedroom: From the bedroom, you can go back to the library, right to the dining room, or descend to the balcony.
# Basement: From the basement, you can go up to the study or forward to the kitchen.
# Patio: From the patio, you can go east to the foyer or south to the dining room.
# Garden: From the garden, you can go north to the living room.
# Pantry: From the pantry, you can go left to the kitchen.
# Balcony: From the balcony, you can go back to the bedroom.
# Bathroom: From the bathroom, you can go back to the foyer, right to the study, or south to the garden.

rooms = {
    "foyer": {"forward": "dining room", "right": "study", "back": "living room", "left": "bathroom"},
    "living room": {"forward": "foyer", "right": "kitchen", "left": "library", "back": "garden"},
    "dining room": {"back": "foyer", "left": "kitchen", "secret": "bedroom", "forward": "patio"},
    "kitchen": {"left": "living room", "forward": "dining room", "basement": "basement", "right": "pantry"},
    "library": {"right": "living room", "secret": "bedroom", "forward": "study", "left": "bathroom"},
    "study": {"left": "foyer", "right": "basement", "back": "library",  "forward": "bathroom"},
    "bedroom": {"forward": "library", "right": "dining room", "back": "balcony"},
    "basement": {"forward": "kitchen", "left": "foyer"},
    "patio": {"right": "foyer", "back": "dining room"},
    "garden": {"forward": "living room"},
    "pantry": {"left": "kitchen"},
    "balcony": {"forward": "bedroom"},
    "bathroom": {"forward": "foyer", "right": "kitchen", "left": "study", "back": "garden"}
}

# Define functions for the game to prevent having to repeat code.
# See, for example, https://www.w3schools.com/python/python_functions.asp

# Define the ghost scare function, this randomly decides if a ghost appears or not.
def scare():
    if random.random() < 0.2:
        print("٩(̾●̮̮̃̾•̃̾)۶ ٩(̾●̮̮̃̾•̃̾)۶ ٩(̾●̮̮̃̾•̃̾)۶")
        print("A ghost appears and scares you!")
        return True
    else:
        return False

# Define the trap door room function
def place_trap_door():
    room_names = list(rooms.keys())
    trap_door_room = random.choice(room_names)
    return trap_door_room

# Define the key room function
def place_key():
    room_names = list(rooms.keys())
    key_room = random.choice(room_names)
    return key_room

# Define the escape room function
def place_escape():
    room_names = list(rooms.keys())
    escape_room = random.choice(room_names)
    return escape_room

# Define the game introduction function, this is so if the same player does not want to play again, they can skip the introduction.
def game_intro():
    name = input("What is your name? ")
    # Ask for gender if gender not supplied from the supported list then set to non-binary
    gender = input("What is your gender? ")
    if gender not in genders:
        print("Setting gender to non-binary")
        gender = "non-binary"
    age = int(input("What is your age? "))
    if age < 11:
        print("You are too young to play this game!")
        quit()

    print(f"Welcome to the haunted house ", name + "!" )
    print_house()
    print("Your goal is to escape the house alive. But beware of the ghosts that haunt the rooms!")
    print("You can move forward, back, left or right. You can also use secret doors to move around the house.")
    print("Good luck!")
    return name, gender, age

# Define the play again function this is so if the same player does not want to play again, they can skip the introduction.
def play_again():
    play_again = input("Do you want to play again? (yes/no) ")
    if play_again == "yes":
        play_game()
    elif play_again == "no":
        print("Game Over! Thanks for playing")
        quit()
    else:
        print("I don't understand that.")
        play_again()

 # For some fun create a function which prints a house in ASCII art
def print_house():
    print("                                              )               (_) ^'^")
    print("         _/\_                    .---------. ((        ^'^")
    print("         (('>                    )`'`'`'`'`( ||                 ^'^")
    print("    _    /^|                    /`'`'`'`'`'`\||           ^'^")
    print("    =>--/__|m---               /`'`'`'`'`'`'`\|")
    print("         ^^           ,,,,,,, /`'`'`'`'`'`'`'`\      ,")
    print("                     .-------.`|`````````````|`  .   )")
    print("                    / .^. .^. \|  ,^^, ,^^,  |  / \ ((")
    print("                   /  |_| |_|  \  |__| |__|  | /,-,\||")
    print('        _         /_____________\ |")| |  |  |/ |_| \|"')
    print('       (")         |  __   __  |  '==' '=='  /_______\     _')
    print('      (' ')        | /  \ /  \ |   _______   |,^, ,^,|    (")')
    print("       \  \        | |--| |--| |  ((--.--))  ||_| |_||   (' ')")
    print('     _  ^^^ _      | |__| |("| |  ||  |  ||  |,-, ,-,|   /  /')
    print("   ,' ',  ,' ',    |           |  ||  |  ||  ||_| |_||   ^^^")
    print(".,,|RIP|,.|RIP|,.,,'==========='==''=='==''=='=======',,....,,,,.,ldb")

# Add a cheat code to skip to the different paths that the game can end for demonstration purposes
def cheater(direction, name, move_counter):
    if direction == 'die':
        print(f"{name}, you cheated! You died!")
        print_death()
        print(f"You cheated to die in ", move_counter ," move(s)!")
        quit()
    elif direction == 'winner':
        print(f"{name}, you cheated! You won!")
        print_success()
        print(f"You cheated to win the game in ", move_counter ," move(s)!")
        quit()
    elif direction == 'terrified':
        print(f"{name}, you cheated! You were terrified!")
        print_ghost()
        print(f"You cheated to be terrified in ", move_counter ," move(s)!")
        quit()

 # For some fun create a function which prints a grim reaper in ASCII art
def print_death():
    print("               ...")
    print("             ;::::;")
    print("           ;::::; :;")
    print("         ;:::::'   :;")
    print("        ;:::::;     ;.")
    print("       ,:::::'       ;           OOO")
    print("       ::::::;       ;          OOOOO")
    print("       ;:::::;       ;         OOOOOOOO")
    print("      ,;::::::;     ;'         / OOOOOOO")
    print("    ;:::::::::`. ,,,;.        /  / DOOOOOO")
    print("  .';:::::::::::::::::;,     /  /     DOOOO")
    print(" ,::::::;::::::;;;;::::;,   /  /        DOOO")
    print(";`::::::`'::::::;;;::::: ,#/  /          DOOO")
    print(":`:::::::`;::::::;;::: ;::#  /            DOOO")
    print("::`:::::::`;:::::::: ;::::# /              DOO")
    print("`:`:::::::`;:::::: ;::::::#/               DOO")
    print(" :::`:::::::`;; ;:::::::::##                OO")
    print(" ::::`:::::::`;::::::::;:::#                OO")
    print(" `:::::`::::::::::::;'`:;::#                O")
    print("  `:::::`::::::::;' /  / `:#")
    print("   ::::::`:::::;'  /  /   `#")

 # For some fun create a function which prints a ghost in ASCII art
def print_ghost():
    print("⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀")
    print("⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣿⣿⣶⣄⠀⠀⠀")
    print("⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⠿⢿⣿⣿⣿⣿⣆⠀⠀")
    print("⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⠁⠀⠿⢿⣿⡿⣿⣿⡆⠀")
    print("⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣦⣤⣴⣿⠃⠀⠿⣿⡇⠀")
    print("⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⡿⠋⠁⣿⠟⣿⣿⢿⣧⣤⣴⣿⡇⠀")
    print("⠀⠀⠀⠀⢀⣠⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⠀⠀⠀⠘⠁⢸⠟⢻⣿⡿⠀⠀")
    print("⠀⠀⠙⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣴⣇⢀⣤⠀⠀⠀⠀⠘⣿⠃⠀⠀")
    print("⠀⠀⠀⠀⠀⢈⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣴⣿⢀⣴⣾⠇⠀⠀⠀")
    print("⠀⠀⣀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀")
    print("⠀⠀⠉⠉⠉⠉⣡⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀")
    print("⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⡿⠟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀")
    print("⠀⠀⣴⡾⠿⠿⠿⠛⠋⠉⠀⢸⣿⣿⣿⣿⠿⠋⢸⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀")
    print("⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⡿⠟⠋⠁⠀⠀⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀")
    print("⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀")

 # For some fun create a function which prints fireworks in ASCII art
def print_success():
    print("                                 .''.")
    print("       .''.             *''*    :_\/_:     . ")
    print("      :_\/_:   .    .:.*_\/_*   : /\ :  .'.:.'.")
    print("  .''.: /\ : _\(/_  ':'* /\ *  : '..'.  -=:o:=-")
    print(" :_\/_:'.:::. /)\*''*  .|.* '.\'/.'_\(/_'.':'.'")
    print(" : /\ : :::::  '*_\/_* | |  -= o =- /)\    '  *")
    print("  '..'  ':::'   * /\ * |'|  .'/.\'.  '._____")
    print('      *        __*..* |  |     :      |.   |\' .---\"|')
    print("       _*   .-'   '-. |  |     .--'|  ||   | _|    |")
    print("    .-'|  _.|  |    ||   '-__  |   |  |    ||      |")
    print("    |' | |.    |    ||       | |   |  |    ||      |")
    print(" ___|  '-'     '    ""       '-'   '-.'    '`      |____")
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")

def print_key():
    print(f" ad8888888888ba ")
    print('dP\'         \`\"8b,\'')
    print('8  ,aaa,       \"Y888a     ,aaaa,     ,aaa,  ,aa,\'')
    print('8  8\' `8           \"8baaaad""""baaaad""""baad""8b')
    print('8  8   8              """"      """"      ""    8b')
    print("8  8, ,8         ,aaaaaaaaaaaaaaaaaaaaaaaaddddd88P")
    print("8  `\"""'       ,d8""")
    print("Yb,         ,ad8\"    ")
    print(" \"Y8888888888P\"")
          
# Define the game function which includes the loop to run until the player escapes or dies
def play_game():
    # Define the initial game state
    current_room = "foyer"
    has_key = False
    is_alive = True
    escaped = False
    move_counter = 0
    scare_counter = 0
    number_of_scares = random.randint(2,5)


# Run the loop and ask player for their next move until they have escaped or died
# A while loop will execute the code inside it as long as the condition is true
# See, https://www.w3schools.com/python/python_while_loops.asp

    while is_alive and not escaped:
        print("You are in the", current_room)
        direction = input("Which direction do you want to go? (forward, back, left, right, secret or quit to give up) ")

        # If statements are used to verify the input and determine the next step
        # See, https://www.w3schools.com/python/python_conditions.asp

        if direction == "quit":
            print("Thank you for playing, goodbye for now")
            quit()
        # Add a cheat code to skip to the different paths that the game can end for demonstration purposes
        elif direction == "die" or direction == "winner" or direction == "terrified":
            cheater(direction, name, move_counter)
        elif direction in rooms[current_room]:
            current_room = rooms[current_room][direction]
            move_counter = move_counter + 1
            if current_room == trap_door_room:
                is_alive = False
                print_death()
                print(f"You fell through the trap door and died after {move_counter} move(s)!")
                play_again()
                break
            if scare():
                scare_counter = scare_counter + 1
                if scare_counter >= number_of_scares:
                    print_ghost()
                    print(f"You are too scared to continue after {move_counter} move(s)!")
                    quit()
            if current_room == key_room:
                has_key = True
                print_key()
                print("You found a key. Keep going")
            if current_room == escape_room and has_key:
                escaped = True
                print_success()
                print(f"You have escaped in {move_counter} move(s)!")
                print("Congratulations", name+"!")
                play_again()
                break
        else:
            print(f"You cannot go {direction} from here. Try another way.")
            continue

# Setup the random assignment of the escape room, trap door room and key room
escape_room = place_escape()
trap_door_room = place_trap_door()
key_room = place_key()
name, gender, age = game_intro()
  
print(f"Escape room is: ", escape_room)
print(f"Trap door room is: ", trap_door_room)
print(f"Key room is: ", key_room)

# Run the game
play_game()
