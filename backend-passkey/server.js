import express from 'express';
import cors from 'cors';
import {
  generateRegistrationOptions,
  verifyRegistrationResponse,
  generateAuthenticationOptions,
  verifyAuthenticationResponse,
} from '@simplewebauthn/server';

const app = express();
app.use(cors());
app.use(express.json());

const rpID = 'localhost';
const origin = 'http://localhost';

const users = new Map();
const regChallenges = new Map();
const authChallenges = new Map();

app.post('/register/options', async (req, res) => {
  const { username } = req.body;
  const user = users.get(username) ?? {
    id: Buffer.from(username).toString('base64url'),
    username,
    credentials: [],
  };

  const options = await generateRegistrationOptions({
    rpName: 'Aora Passkey Demo',
    rpID,
    userID: user.id,
    userName: user.username,
    attestationType: 'none',
    authenticatorSelection: {
      residentKey: 'required',
      userVerification: 'required',
    },
    excludeCredentials: user.credentials.map((c) => ({ id: c.id, type: 'public-key' })),
  });

  regChallenges.set(username, options.challenge);
  users.set(username, user);
  res.json(options);
});

app.post('/register/verify', async (req, res) => {
  const { username, credential } = req.body;
  const user = users.get(username);

  const verification = await verifyRegistrationResponse({
    response: credential,
    expectedChallenge: regChallenges.get(username),
    expectedOrigin: origin,
    expectedRPID: rpID,
  });

  if (verification.verified && verification.registrationInfo) {
    user.credentials.push({
      id: verification.registrationInfo.credential.id,
      publicKey: verification.registrationInfo.credential.publicKey,
      counter: verification.registrationInfo.credential.counter,
      transports: verification.registrationInfo.credential.transports,
    });
    users.set(username, user);
  }

  res.json({ verified: verification.verified });
});

app.post('/login/options', async (req, res) => {
  const { username } = req.body;
  const user = users.get(username);

  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }

  const options = await generateAuthenticationOptions({
    rpID,
    userVerification: 'required',
    allowCredentials: user.credentials.map((c) => ({
      id: c.id,
      type: 'public-key',
      transports: c.transports,
    })),
  });

  authChallenges.set(username, options.challenge);
  res.json(options);
});

app.post('/login/verify', async (req, res) => {
  const { username, credential } = req.body;
  const user = users.get(username);

  const authenticator = user.credentials.find((c) => c.id === credential.id);
  if (!authenticator) {
    return res.status(400).json({ verified: false, error: 'Authenticator not found' });
  }

  const verification = await verifyAuthenticationResponse({
    response: credential,
    expectedChallenge: authChallenges.get(username),
    expectedOrigin: origin,
    expectedRPID: rpID,
    authenticator,
  });

  if (verification.verified) {
    authenticator.counter = verification.authenticationInfo.newCounter;
  }

  res.json({ verified: verification.verified });
});

app.listen(3000, () => {
  console.log('Passkey server listening on http://localhost:3000');
});
