import {
  to = aws_subnet.this["public-subnet-a"]
  id = "subnet-0b97151b8f1f45bf4"
}

import {
  to = aws_subnet.this["public-subnet-b"]
  id = "subnet-00b75dbeba81e03bf"
}

import {
  to = aws_subnet.this["private-subnet-a"]
  id = "subnet-08c3d7f438768df76"
}

import {
  to = aws_subnet.this["private-subnet-b"]
  id = "subnet-098ec3f47e7c51d38"
}

import {
  to = aws_eip.nat
  id = "eipalloc-00e8909f2e8cf7b2b"
}

import {
  to = aws_nat_gateway.this
  id = "nat-01324c8568b3995de"
}

import {
  to = aws_route_table.public
  id = "rtb-0e1ec05032522d859"
}

import {
  to = aws_route_table.private
  id = "rtb-06b90fcca6bbee54d"
}

# Associations using Correct Format: subnet_id/route_table_id
import {
  to = aws_route_table_association.this["public-subnet-a"]
  id = "subnet-0b97151b8f1f45bf4/rtb-0e1ec05032522d859"
}

import {
  to = aws_route_table_association.this["public-subnet-b"]
  id = "subnet-00b75dbeba81e03bf/rtb-0e1ec05032522d859"
}

import {
  to = aws_route_table_association.this["private-subnet-a"]
  id = "subnet-08c3d7f438768df76/rtb-06b90fcca6bbee54d"
}

import {
  to = aws_route_table_association.this["private-subnet-b"]
  id = "subnet-098ec3f47e7c51d38/rtb-06b90fcca6bbee54d"
}
