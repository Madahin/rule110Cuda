#ifndef GAME
#define GAME

#include <SDL2/SDL.h>
#include <stdio.h>
#include <stdlib.h>

#define CELL_SIZE 1

typedef struct Game Game;
struct Game{
    unsigned int  m_width;
    unsigned int  m_height;
    unsigned int* m_width_device;
    unsigned int* m_height_device;
    SDL_Window*   m_window;
    SDL_Renderer* m_renderer;
    size_t        m_cellDataSize;
    char*         m_cellData_host;
    char*         m_cellData_device;
};

Game* initGame(unsigned int width, unsigned int height);
void playGame(Game* ptr);
void resetGame(Game* ptr, int type);
void deleteGame(Game* ptr);

__global__ void computeCell(char* cellData, unsigned int* width, unsigned int* height);
__device__ char* applyRule(char* left, char* middle, char* right);

#endif
