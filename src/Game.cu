#include "../include/Game.h"

Game* initGame(unsigned int width, unsigned int height)
{
    if (SDL_Init(SDL_INIT_VIDEO) != 0 )
    {
        fprintf(stderr,"SDL_init error :  %s\n",SDL_GetError());
        return NULL;
    }

    Game* ptr     = (Game*)malloc(sizeof(Game)); 
    ptr->m_width  = width;
    ptr->m_height = height;
    ptr->m_window = NULL;
    ptr->m_window = SDL_CreateWindow("rule110Cuda",
            SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED,
            ptr->m_width,
            ptr->m_height,
            SDL_WINDOW_OPENGL);

    if(ptr->m_window == NULL)
    {
        fprintf(stderr, "SDL_CreateWindow error : %s\n", SDL_GetError());
        free(ptr);
        ptr = NULL;
    }

    ptr->m_renderer = NULL;
    ptr->m_renderer = SDL_CreateRenderer(ptr->m_window, 0, SDL_RENDERER_ACCELERATED);

    ptr->m_cellDataSize = sizeof(char) * ptr->m_width * ptr->m_height / (CELL_SIZE);

    unsigned int tmpWidth = ptr->m_width / (CELL_SIZE);
    unsigned int tmpHeight = ptr->m_height / (CELL_SIZE);

    cudaMalloc((void**)&(ptr->m_width_device), sizeof(unsigned int));
    cudaMalloc((void**)&(ptr->m_height_device), sizeof(unsigned int));

    cudaMemcpy(ptr->m_width_device, &tmpWidth, sizeof(unsigned int), cudaMemcpyHostToDevice);
    cudaMemcpy(ptr->m_height_device, &tmpHeight, sizeof(unsigned int), cudaMemcpyHostToDevice);

    ptr->m_cellData_host = (char*) malloc(ptr->m_cellDataSize);
    cudaMalloc((void**) &(ptr->m_cellData_device), ptr->m_cellDataSize);

    resetGame(ptr, 1);

    return ptr;
}

void playGame(Game* ptr)
{
    SDL_Event event;
    short run = 0;

    const unsigned int sizeX = ptr->m_width / (CELL_SIZE);
    const unsigned int sizeY = ptr->m_height / (CELL_SIZE); 

    while(run == 0)
    {
        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
                case SDL_QUIT:
                    {
                        run = 1;
                        break;
                    }
                case SDL_KEYUP:
                    {
                        if(event.key.keysym.sym == SDLK_r){
                            resetGame(ptr, 0);
                        }else if(event.key.keysym.sym == SDLK_e){
                            resetGame(ptr, 1);
                        }
                        break;
                    }
            }
        }
        SDL_SetRenderDrawColor(ptr->m_renderer, 0, 0, 0, 255);
        SDL_RenderClear(ptr->m_renderer);

        unsigned int x = 0;
        unsigned int y = 0;

        for(y=0; y < sizeY; ++y){
            for(x=0; x < sizeX; ++x){
                SDL_Rect r;
                r.x = x * CELL_SIZE;
                r.y = y * CELL_SIZE;
                r.w = CELL_SIZE;
                r.h = CELL_SIZE;


                if(ptr->m_cellData_host[x + y * sizeX] == 1){
                    SDL_SetRenderDrawColor(ptr->m_renderer, 255, 255, 255, 255);
                } else {
                    SDL_SetRenderDrawColor(ptr->m_renderer, 0, 0, 0, 255);
                }
                SDL_RenderFillRect(ptr->m_renderer, &r);
            }
        }

        SDL_RenderPresent(ptr->m_renderer);
        SDL_Delay(16);
    }
}

__device__ void applyRule(char* left, char* middle, char* right, char* res){
    char a = *left;
    char b = *middle;
    char c = *right;

    if(a == 0 && b == 0 && c == 0){
        *res = 0;
    }else if(a == 0 && b == 0 && c == 1){
        *res = 1;
    }else if(a == 0 && b == 1 && c == 0){
        *res = 1;
    }else if(a == 0 && b == 1 && c == 1){
        *res = 1;
    }else if(a == 1 && b == 0 && c == 0){
        *res = 0;
    }else if(a == 1 && b == 0 && c == 1){
        *res = 1;
    }else if(a == 1 && b == 1 && c == 0){
        *res = 1;
    }else if(a == 1 && b == 1 && c == 1){
        *res = 0;
    }
}

__global__ void computeCell(char* cellData, unsigned int* width, unsigned int* height)
{
    int y = 0;
    int x = 0;

    /*
       printf("width : %d\n", *width);
       printf("height : %d\n", *height);
       printf("dimblock : %d\n", blockDim.x);
       printf("threadid : %d\n", threadIdx.x);
     */

    for(y=1; y < (*height); ++y){
        for(x=threadIdx.x; x < (*width); x += blockDim.x){
            char left = ((x-1)>=0) ? cellData[(x-1) + (y-1) * (*width)] : 0;
            char middle = cellData[x + (y-1) * (*width)];
            char right = ((x+1) < *width) ? cellData[(x+1) + (y-1) * (*width)] : 0;

            //printf("left   : (%d, %d) => %d : %d\n", x-1, y-1, (x-1) + (y-1) * (*width), left);
            //printf("middle : (%d, %d) => %d : %d\n", x, y-1, (x) + (y-1) * (*width), middle);
            //printf("right  : (%d, %d) => %d : %d\n", x+1, y-1, (x+1) + (y-1) * (*width), right);
            applyRule(&left, &middle, &right, &cellData[x + y * (*width)]);
            //printf("res    : (%d, %d) => %d : %d\n", x, y, x + y * (*width), cellData[x+y*(*width)]);

            //printf("-----------\n");
        }
        __syncthreads();
    }

    /*
       for(y=0; y < *height; ++y){
       for(x=0; x < *width; ++x){
       printf("(%d, %d) = %d\n", x, y, cellData[x+y*(*width)]);
       }
       }
     */
}

void resetGame(Game* ptr, int type)
{
    const unsigned int SIZE = ptr->m_width / (CELL_SIZE);
    if(type == 0){
        unsigned int i = 0;
        for(i=0; i < SIZE; ++i){
            ptr->m_cellData_host[i] = rand() % 2;
        }
    }else if(type == 1){
        ptr->m_cellData_host[SIZE-1] = 1;
    }
    cudaMemcpy(ptr->m_cellData_device, ptr->m_cellData_host, sizeof(char) * SIZE, cudaMemcpyHostToDevice);
    computeCell<<<1, 256>>>(ptr->m_cellData_device, ptr->m_width_device, ptr->m_height_device);
    cudaError err = cudaGetLastError();
    if(err != cudaSuccess){
        printf("Error : %s\n", cudaGetErrorString(err));
    }
    cudaDeviceSynchronize();
    cudaMemcpy(ptr->m_cellData_host, ptr->m_cellData_device, ptr->m_cellDataSize, cudaMemcpyDeviceToHost);
}

void deleteGame(Game* ptr)
{
    SDL_DestroyWindow(ptr->m_window);
    SDL_DestroyRenderer(ptr->m_renderer);
    SDL_Quit();
    free(ptr->m_cellData_host);
    cudaFree(ptr->m_cellData_device);
    cudaFree(ptr->m_width_device);
    cudaFree(ptr->m_height_device);
    free(ptr);
    ptr = NULL; 
}
