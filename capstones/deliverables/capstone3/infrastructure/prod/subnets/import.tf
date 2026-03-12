import {
  to = aws_subnet.this["public-subnet-a"]
  id = "subnet-0a75e6143717f9002"
}

import {
  to = aws_subnet.this["public-subnet-b"]
  id = "subnet-0cfe9deaf75ffaac3"
}

import {
  to = aws_subnet.this["private-subnet-a"]
  id = "subnet-057f674fe10aedc94"
}

import {
  to = aws_subnet.this["private-subnet-b"]
  id = "subnet-012db0dcd77309b67"
}

import {
  to = aws_nat_gateway.this
  id = "nat-0bd5a95cae7626a84"
}

import {
  to = aws_eip.nat
  id = "eipalloc-04aec190cc66c9934"
}

import {
  to = aws_route_table.public
  id = "rtb-02828d2ba607b4b53"
}

import {
  to = aws_route_table.private
  id = "rtb-05a1f9a17223f519d"
}

# Associations using Correct Format: subnet_id/route_table_id
import {
  to = aws_route_table_association.this["public-subnet-a"]
  id = "subnet-0a75e6143717f9002/rtb-02828d2ba607b4b53"
}

import {
  to = aws_route_table_association.this["public-subnet-b"]
  id = "subnet-0cfe9deaf75ffaac3/rtb-02828d2ba607b4b53"
}

import {
  to = aws_route_table_association.this["private-subnet-a"]
  id = "subnet-057f674fe10aedc94/rtb-05a1f9a17223f519d"
}

import {
  to = aws_route_table_association.this["private-subnet-b"]
  id = "subnet-012db0dcd77309b67/rtb-05a1f9a17223f519d"
}
