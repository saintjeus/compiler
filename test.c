int x;
int y;
int z;

main(){
x = 9;
y = 5;
z = 9;

printf("x is %d\n", x);
printf("y is %d\n", y);
printf("z is %d\n", z);

if(x > y){ printf("x is greater!\n");}
else{ printf("y is greater!this shouldn't execute\n");}

if (x < y){printf("x is smaller!this shouldn't execute\n");}
else{printf("y is smaller!\n");}

if (x != y){printf("x is not equal to y!\n");}
else {printf("x is equal to y!this shouldn't execute\n");}

if (x == z){printf("x is equal to z!\n");}
else {printf("x is not equal to z!this shouldn't execute\n");}

while (y < x) {
	printf("while y < x. x = %d. y = %d\n", x, y); 
	y = y + 1;}

y=5;

while (x > y) {
	printf("while x > y. x = %d. y = %d\n", x, y); 
	x = x - 1;
	}


}

