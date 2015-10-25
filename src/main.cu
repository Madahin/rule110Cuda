#include <SDL2/SDL.h>
#include <stdio.h>
#include <time.h>
#include <cuda.h>

#include "../include/Game.h"

int main(int argc, char** argv)
{
    srand(time(NULL));

    Game * g = NULL;
    g = initGame(1024, 768);
    if(g == NULL)
    {
        return -1;
    }

    playGame(g);
    
    deleteGame(g);
    
    return 0;
}
