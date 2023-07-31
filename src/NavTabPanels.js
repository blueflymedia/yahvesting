import Nav from 'react-bootstrap/Nav';

const NavTabPanels = () => {
  return (
    <Nav variant="tabs" defaultActiveKey="/home">
      <Nav.Item>
        <Nav.Link href="/home">Stake Tokens</Nav.Link>
      </Nav.Item>
      <Nav.Item>
        <Nav.Link eventKey="link-1">Withdraw Tokens</Nav.Link>
      </Nav.Item>
      <Nav.Item>
        <Nav.Link eventKey="link-2">Option 3</Nav.Link>
      </Nav.Item>
    </Nav>
  );
}

export default NavTabPanels;