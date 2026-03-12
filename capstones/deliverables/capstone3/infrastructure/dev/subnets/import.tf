import {
  to = aws_subnet.this["public-subnet-a"]
  id = "subnet-0fe81f9f2a4413faa"
}

import {
  to = aws_subnet.this["public-subnet-b"]
  id = "subnet-00868114c0f8cbba8"
}

import {
  to = aws_subnet.this["private-subnet-a"]
  id = "subnet-0781eaa1a75100e99"
}

import {
  to = aws_subnet.this["private-subnet-b"]
  id = "subnet-0dbcb1918fab4cd67"
}

import {
  to = aws_eip.nat
  id = "eipalloc-09e9336c8aaa26305"
}

import {
  to = aws_nat_gateway.this
  id = "nat-0c1a2ec6fec341e0c"
}

import {
  to = aws_route_table.public
  id = "rtb-075a286fb79e923fb"
}

import {
  to = aws_route_table.private
  id = "rtb-0dc216047c88ba964"
}

# Associations using Correct Format: subnet_id/route_table_id
import {
  to = aws_route_table_association.this["public-subnet-a"]
  id = "subnet-0fe81f9f2a4413faa/rtb-075a286fb79e923fb"
}

import {
  to = aws_route_table_association.this["public-subnet-b"]
  id = "subnet-00868114c0f8cbba8/rtb-075a286fb79e923fb"
}

import {
  to = aws_route_table_association.this["private-subnet-a"]
  id = "subnet-0781eaa1a75100e99/rtb-0dc216047c88ba964"
}

import {
  to = aws_route_table_association.this["private-subnet-b"]
  id = "subnet-0dbcb1918fab4cd67/rtb-0dc216047c88ba964"
}
