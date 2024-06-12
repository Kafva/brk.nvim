from random import randint

def gen_random():
   x = randint(0,1)
   y = randint(0,2)
   z = randint(0,3)
   return randint(0,1000) / max(1,x+y+z)

def gen_randoms(cnt):
    for i in range(0,cnt):
        print(f"{i}: {gen_random()}")


if __name__ == '__main__':
    gen_randoms(10)

