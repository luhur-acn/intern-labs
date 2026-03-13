import {
  to = aws_subnet.this["public-subnet-a"]
  id = "subnet-01b9ec21812851fb9"
}

import {
  to = aws_subnet.this["public-subnet-b"]
  id = "subnet-071e6ada797f069b2"
}

import {
  to = aws_subnet.this["private-subnet-a"]
  id = "subnet-043a9e41961018387"
}

import {
  to = aws_subnet.this["private-subnet-b"]
  id = "subnet-028249dd15e714880"
}

import {
  to = aws_nat_gateway.this
  id = "nat-0b89d15af72a8958f"
}

import {
  to = aws_eip.nat
  id = "eipalloc-0f61390e84aa08b64"
}

import {
  to = aws_route_table.public
  id = "rtb-0096b2c3cf9bc8913"
}

import {
  to = aws_route_table.private
  id = "rtb-07fb418c9132e1204"
}

# Associations using Correct Format: subnet_id/route_table_id
import {
  to = aws_route_table_association.this["public-subnet-a"]
  id = "subnet-01b9ec21812851fb9/rtb-0096b2c3cf9bc8913"
}

import {
  to = aws_route_table_association.this["public-subnet-b"]
  id = "subnet-071e6ada797f069b2/rtb-0096b2c3cf9bc8913"
}

import {
  to = aws_route_table_association.this["private-subnet-a"]
  id = "subnet-043a9e41961018387/rtb-07fb418c9132e1204"
}

import {
  to = aws_route_table_association.this["private-subnet-b"]
  id = "subnet-028249dd15e714880/rtb-07fb418c9132e1204"
}
