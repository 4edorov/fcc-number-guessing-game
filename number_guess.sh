#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo -e "\nEnter your username:"
read USERNAME

PLAYER_ID=$($PSQL "SELECT player_id FROM players WHERE name='$USERNAME'")

if [[ -z $PLAYER_ID ]]
then
  CREATE_PLAYER_RESULT=$($PSQL "INSERT INTO players(name) VALUES('$USERNAME')")
  PLAYER_ID=$($PSQL "SELECT player_id FROM players WHERE name='$USERNAME'")
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
else
  PLAYER_INFO_RESULT=$($PSQL "SELECT COUNT(*), MIN(guess_count) FROM players RIGHT JOIN games USING(player_id) WHERE player_id=$PLAYER_ID")
  IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$PLAYER_INFO_RESULT"
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

RANDOM_INT=$(shuf -i 1-1000 -n 1)
NUMBER_OF_GUESSES=0

READ_GUESS() {
  if [[ $# -ge 1 ]]
  then
    echo -e "\n$1"
  fi

  read GUESS

  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    READ_GUESS "That is not an integer, guess again:"
  else
    NUMBER_OF_GUESSES=$(($NUMBER_OF_GUESSES + 1))

    if (( $GUESS > $RANDOM_INT ))
    then
      READ_GUESS "It's higher than that, guess again:"
    elif (( $GUESS < $RANDOM_INT ))
    then
      READ_GUESS "It's lower than that, guess again:"
    else
      INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(guess_count, player_id) VALUES($NUMBER_OF_GUESSES, $PLAYER_ID)")
      echo -e "\nYou guessed it in $NUMBER_OF_GUESSES tries. The secret number was $RANDOM_INT. Nice job!"
    fi
  fi
}

READ_GUESS "Guess the secret number between 1 and 1000:"
