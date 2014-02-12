# demonstrates the use of pch=0 for pixels

using SixelGraphics

n = 128
x = 0.1*ones(n)
for i=2:n
  x[i] = 4*x[i-1]*(1-x[i-1])
end

y = x[2:n]
x = x[1:n-1]

sixelplot(x,y, title="Logistic Map", xlab="x[i]", ylab="x[i+1]",
          xlim=[0,1], ylim=[0,1], typ='p', pch=0)
